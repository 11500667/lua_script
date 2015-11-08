local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--获取市ID
local shi = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")
--获取区ID
local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
--获取校ID
local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")

--获取学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]
--获取学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]
--获取上传文件大小
if args["size"] == nil or args["size"] == "" then
    ngx.say("{\"success\":false,\"info\":\"size参数错误！\"}")
    return
end
local size = args["size"]
--获取上传的类型  1：资源  3：试卷  2：试题  4：备课   5：微课
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"]
--资源个数，传count按count值计算，不传就加1
local count = "1"
if args["count"] ~= nil then
     count = args["count"] 
end

--今天是哪年哪月哪日 例:20141202
local today = os.date("%Y%m%d")

local type_name = ""
if type_id == "1" then	
    type_name = "zy"
elseif type_id=="2" then
    type_name = "st"
elseif type_id=="3" then
    type_name = "sj"
elseif type_id=="4" then
    type_name = "bk"
else
    type_name = "wk"
end
--获取媒体类型
if args["mtype"] == nil or args["mtype"] == "" then
    ngx.say("{\"success\":false,\"info\":\"mtype参数错误！\"}")
    return
end
local mtype = args["mtype"]

if type_name == "wk" then
	mtype = "4"
end
if type_name == "st" then
	mtype = "0"
end
if type_name == "bk" then
	mtype = "2"
end


--连接SSDB
local ssdb = require "resty.ssdb"
local db = ssdb:new()
local ok, err = db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

if type_id == "1" then	
	db:hincr("tj_zy_all","total_count",count)
	db:hincr("tj_zy_all","total_size",size)
	db:hincr("tj_zy_today_"..today,"upload_count",count)
elseif type_id=="2" then
	db:hincr("tj_st_all","total_count",count)
	db:hincr("tj_st_all","total_size",size)
	db:hincr("tj_st_today_"..today,"upload_count",count)
elseif type_id=="3" then
	db:hincr("tj_sj_all","total_count",count)
	db:hincr("tj_sj_all","total_size",size)
	db:hincr("tj_sj_today_"..today,"upload_count",count)
elseif type_id=="4" then
	db:hincr("tj_bk_all","total_count",count)
	db:hincr("tj_bk_all","total_size",size)
	db:hincr("tj_bk_today_"..today,"upload_count",count)
else
	db:hincr("tj_wk_all","total_count",count)
	db:hincr("tj_wk_all","total_size",size)
	db:hincr("tj_wk_today_"..today,"upload_count",count)
end

db:set("generate_ts",888)


local bureau_id = cache:hget("person_"..cookie_person_id.."_5","xiao")
if bureau_id ~= ngx.null then
	if tostring(bureau_id) ~= "400195" then
		--管道开始
		db:init_pipeline()
		--只有资源和微课才存
		--if type_id == "1" or type_id == "5" then        
			--*********保存市的信息************
			--tj_all_res_市ID_区ID_学段ID_学科ID (HASH)   每个单元格的资源个数和资源大小
			db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id,"resource_count",count)
			db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id,"resource_size",size)
				
			--tj_all_res_市ID_区ID_学段ID (HASH)	 每个区横向的合计
			db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id,"resource_count",count)
			db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id,"resource_size",size)
			
			--tj_all_res_市ID_学段ID_学科ID_zset (ZSET)	 按学科排序形成区的顺序
			db:zincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id.."_"..subject_id.."_zset",qu)
			
			--tj_all_res_市ID_学段ID (ZSET)	横向合计的排序
			db:zincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id,qu)    
			
			--tj_all_res_市ID_学段ID_学科ID_hash (HASH)   最底下的合计
			db:hincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id.."_"..subject_id.."_hash","resource_count",count)
			db:hincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id.."_"..subject_id.."_hash","resource_size",size)
			
			db:hincr("tj_bureau_"..type_name.."_"..shi.."_all","resource_count",count)
			db:hincr("tj_bureau_"..type_name.."_"..shi.."_all","resource_size",size)
			
			--*********保存区的信息************
			--tj_qu_res_市ID_区ID_校ID_学段ID_学科ID (HASH)   每个单元格的资源个数和资源大小
			db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_count",count)
			db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_size",size)
			
			--tj_qu_res_市ID_区ID_校ID_学段ID (HASH)	 每个区横向的合计
			db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id,"resource_count",count)
			db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id,"resource_size",size)
			
			--tj_qu_res_市ID_区ID_学段ID_学科ID_zset (ZSET)	 按学科排序形成区的顺序
			db:zincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id.."_zset",xiao)
			
			--tj_qu_res_市ID_区ID_学段ID (ZSET)	横向合计的排序
			db:zincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id,xiao)
			
			--tj_qu_res_市ID_区ID_学段ID_学科ID_hash (HASH)   最底下的合计
			db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id.."_hash","resource_count",count)
			db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id.."_hash","resource_size",size)  

			db:hincr("tj_bureau_"..type_name.."_"..qu.."_all","resource_count",count)
			db:hincr("tj_bureau_"..type_name.."_"..qu.."_all","resource_size",size)	
			
			--*********保存校的信息************
			--tj_xiao_res_市ID_区ID_校ID_学段ID_学科ID_类型ID (HASH)	每个单元格的资源个数和资源大小
			db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id.."_"..mtype,"resource_count",count)
			db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id.."_"..mtype,"resource_size",size)
			
			--tj_xiao_res_市ID_区ID_校ID_学段ID_学科ID (HASH)	每科横向的合计
			db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_count",count)
			db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_size",size)
			
			--tj_xiao_res_市ID_区ID_校ID_学段ID_类型ID_zset (ZSET)	按类型排序形成的学科顺序
			db:zincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..mtype.."_zset",subject_id)
			
			--tj_xiao_res_市ID_区ID_校ID_学段ID (ZSET)		横向合计的排序
			db:zincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id,subject_id)
			
			--tj_xiao_res_市ID_区ID_校ID_学段ID_类型ID_hash (HASH)	最底下的合计
			db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..mtype.."_hash","resource_count",count)
			db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..mtype.."_hash","resource_size",size)
			
			--新增记录校下总合
			db:hincr("tj_bureau_"..type_name.."_"..xiao.."_all","resource_count",count)
			db:hincr("tj_bureau_"..type_name.."_"..xiao.."_all","resource_size",size)
			
			--资源评份排序用的SSDB
			db:hincr("resource_score_all","resource_count")
			
			
		--end

		--管道提交
		local results, err = db:commit_pipeline()
		if not results then  
			ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
	end
end



--只有资源、试卷和备课才存
if type_id == "1" or type_id == "3" or type_id == "4" or type_id == "5" then 
    --local res = ngx.location.capture("/dsideal_yy/ypt/workroom/getWorkroomByPersonId?person_id="..cookie_person_id)
    --local str =  cjson.decode(res.body)
    --local workroom_ids = str.workroom_ids
    --if workroom_ids ~= "" then		
	if args["wrids"] ~= nil or args["wrids"] ~= "" then	
		if args["wrids"] ~= "-1" then
			local wr_id = Split(args["wrids"],",")
			for i=1,#wr_id do
				--获取工作室今天是几号
				local wr_today = db:hget("workroom_tj_"..wr_id[i],"today")[1]
				--判断工作室今天的属性值和现实今天是不是一样
				if wr_today == today then
					--一样的话today_upload+1
					db:hincr("workroom_tj_"..wr_id[i],"today_upload") 
				else
					--不一样就把today改成一样的，再将today_upload重置为1
					db:hset("workroom_tj_"..wr_id[i],"today",today)
					db:hset("workroom_tj_"..wr_id[i],"today_upload","1")
				end
				--资源总数+1
				db:hincr("workroom_tj_"..wr_id[i],"resource_count",count)

				--更新记录统计json的TS值
				local  workroom_tj_ts = math.random(1000000)..os.time()
				db:set("workroom_tj_ts_"..wr_id[i],workroom_tj_ts)
				
				--工作室总数
				db:hincr("workroom_tj_all","resource_count")
				
			end
		end
	end      
    
end

--云平台门户
--统计信息
db:hincr("tj_"..type_name.."_all","total_count",count) --资源总数
db:hincr("tj_"..type_name.."_all","total_size",size) --资源总大小

--今日统计
db:hincr("tj_"..type_name.."_today".."_"..today,"upload_count",count) --今天上传数
--设置今日统计的过期时间
db:expire("tj_"..type_name.."_today".."_"..today,"172800")

--为唐山增加的活跃人和单位
if shi == "200004" then
	db:zincr("active_user_"..shi,cookie_person_id)
	db:zincr("active_bureau_"..shi,xiao)
	
	local cjson = require "cjson"
	
	local res_body = ngx.location.capture("/dsideal_yy/ypt/workroom/bteacher?person_id="..cookie_person_id)
	local is_ms = cjson.decode(res_body.body)["bteacher"]	
	if is_ms == "1" then
		db:zincr("workroom_hot_"..shi,cookie_person_id)
	end	
end

--更新记录统计json的TS值
local  tj_ts = math.random(1000000)..os.time()
db:set("tj_ts",tj_ts)
db:set("tj_today",today)

--张海的接口
local service = require("space.gzip.service.BakToolsUpdateTsService") 
service.updateTs(cookie_person_id,cookie_identity_id) 

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
db:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":ture}")
