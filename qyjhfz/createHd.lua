--[[
创建活动
@Author  chenxg
@Date    2015-03-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local quote = ngx.quote_sql_str

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--参数 
--在哪个页面添加活动 3：大学区 4:协作体
local page_type = args["page_type"]
--大学区或者协作体ID
local path_id = args["path_id"]
--活动类型：1培训学习2专家讲座3集体备课4教学观摩5交流研讨
local hd_type = args["hd_type"]

local active_name = args["active_name"]--活动名称
local subject_id = args["subject_id"]--学段科目
local start_date = args["start_date"]--开始时间
local end_date = args["end_date"]--结束时间
local con_pass = args["con_pass"]--会议密码

--一期这些参数不配置，全部从配置文件读取
--[[
local acitve_peo = args["acitve_peo"]--会议用户数
local mod_pass = args["mod_pass"]--主持人密码
local video_num = args["video_num"]--视频数目
local speech = args["speech"]--发言人数
]]
local description = args["description"]--描述
local person_id = args["person_id"]--当前用户

--从cookie获取当前用户的省市区ID
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--创建redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

--判断参数是否为空
if not page_type or string.len(page_type) == 0 
  or not path_id or string.len(path_id) == 0 
  or not hd_type or string.len(hd_type) == 0 
  or not active_name or string.len(active_name) == 0 
  or not start_date or string.len(start_date) == 0
  or not end_date or string.len(end_date) == 0  
  or not person_id or string.len(person_id) == 0 
  or not subject_id or string.len(subject_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

local hd = {}
local ts1 = os.date("%Y-%m-%d %H:%M:%S")
local n = ngx.now();
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts = ts..string.rep("0",19-string.len(ts));
local id = cache:incr("t_qyjh_hd_pk")
--取协作体id
local hd_id = ssdb:incr("qyjh_pk")[1]
local qyjh_id = ""
local hd_confid = ""

--跟告白特对接开始 陈续刚2014-02-09添加
local status = 200

if hd_type ~="1" then
	local res_hd, err = ngx.location.capture("/createHDForGBT", {
		args = {active_name = active_name,start_date = start_date,end_date = end_date,con_pass = con_pass}
	})
	status = res_hd.status
	--ngx.log(ngx.ERR,"=======>"..cjson.decode(res_hd).."<=======")
	if status == 200 then
		hd_confid = cjson.decode(res_hd.body).confid
	else
		say("{\"success\":false,\"info\":\"连接高百特创建活动失败！\",\"GBT_OPEN\":false}")
		return
	end
end
if status == 200 then
	if hd_type =="1" then
		hd_confid = hd_id	
	end
	--*********************
	--存储活动跟大学区对应关系信息
	if page_type == "3" then 
		local hdxq = ssdb:hget("qyjh_dxq",path_id)
		local dxq = cjson.decode(hdxq[1])
		qyjh_id = dxq.qyjh_id
		
		hd.dxq_id=path_id
		hd.qyjh_id=qyjh_id
		
		ssdb:zset("qyjh_dxq_hds_"..path_id,hd_id,ts)
		ssdb:zset("qyjh_dxq_hds_"..path_id.."_"..hd_type,hd_id,ts)
		--大学区下活动数量
		local hastj = ssdb:hget("qyjh_dxq_tj_"..path_id,"hd_tj")
		if not hastj or string.len(hastj[1]) == 0 then
			ssdb:hset("qyjh_dxq_tj_"..path_id,"hd_tj",0)
		end
		local hastypetj = ssdb:hget("qyjh_dxq_tj_"..path_id.."_"..hd_type,"hd_tj")
		if not hastypetj or string.len(hastypetj[1]) == 0 then
			ssdb:hset("qyjh_dxq_tj_"..path_id.."_"..hd_type,"hd_tj",0)
		end
		ssdb:hincr("qyjh_dxq_tj_"..path_id,"hd_tj",1)
		ssdb:hincr("qyjh_dxq_tj_"..path_id.."_"..hd_type,"hd_tj",1)
	--存储活动跟协作体对应关系信息
	elseif page_type == "4" then 
		ssdb:zset("qyjh_xzt_hds_"..path_id,hd_id,ts)
		ssdb:zset("qyjh_xzt_hds_"..path_id.."_"..hd_type,hd_id,ts)
		--大学区活动数量+1
		local hxzt = ssdb:hget("qyjh_xzt",path_id)
		local xzt = cjson.decode(hxzt[1])
		qyjh_id = xzt.qyjh_id
		
		hd.xzt_id=path_id
		hd.dxq_id=xzt.dxq_id
		hd.qyjh_id=qyjh_id
		
		--大学区活动数量+1
		ssdb:hincr("qyjh_dxq_tj",xzt.dxq_id.."_hd_tj",1)
		ssdb:hincr("qyjh_dxq_tj",xzt.dxq_id.."_"..hd_type.."_hd_tj",1)
		--协作体活动数量+1
		ssdb:hincr("qyjh_xzt_tj",path_id.."_hd_tj",1)
		ssdb:hincr("qyjh_xzt_tj",path_id.."_"..hd_type.."_hd_tj",1)
		
		--协作体活动数量加1
		ssdb:zincr("qyjh_xzt_sort_"..xzt.dxq_id,path_id,1)
		ssdb:zincr("qyjh_qyjh_xzt_sort_"..xzt.qyjh_id,path_id,1)
		
		--往mysql表中存储活动信息
		local stonum = start_date
		stonum = string.gsub(stonum,"-","")
		stonum = string.gsub(stonum,":","")
		stonum = string.gsub(stonum," ","")
		local insertSql = "insert into t_qyjh_hd (id,qyjh_id,dxq_id,xzt_id,person_id,hd_name,hd_id,lx_id,statu,start_time,end_time,create_time,ts,subject_id,startts)values("
				..hd_id..","..quote(qyjh_id)..","..quote(xzt.dxq_id)..","..quote(path_id)..","..quote(person_id)..","..quote(active_name)..","..quote(hd_id)..","..quote(hd_type)..",-1,"..quote(start_date)..","..quote(end_date)..","..quote(ts1)..","..quote(ts)..","..quote(subject_id)..","..quote(stonum*100)..")";
				--ngx.log(ngx.ERR,"**********"..insertSql.."*************8")
		local ok, err = db:query(insertSql)
		--[[if ok then
			cache:hmset("qyjh_hd_"..id, "id", id, "hd_id",hd_id)
		end]]
	end

	--(1)存储活动跟区域均衡对应关系信息
	ssdb:zset("qyjh_qyjh_hds_"..qyjh_id,hd_id,ts)
	ssdb:zset("qyjh_qyjh_hds_"..qyjh_id.."_"..hd_type,hd_id,ts)
	--活动数量
	local hastj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"hd_tj")
	if not hastj or string.len(hastj[1]) == 0 then
		ssdb:hset("qyjh_qyjh_tj_"..qyjh_id,"hd_tj",0)
	end
	local hastypetj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id.."_"..hd_type,"hd_tj")
	if not hastypetj or string.len(hastypetj[1]) == 0 then
		ssdb:hset("qyjh_qyjh_tj_"..qyjh_id.."_"..hd_type,"hd_tj",0)
	end
	ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"hd_tj",1)
	ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id.."_"..hd_type,"hd_tj",1)
		
	--存储详细信息

	hd.hd_id = hd_id
	hd.mysql_id = id
	hd.subject_id = subject_id
	hd.hd_confid = hd_confid
	hd.page_type = page_type
	hd.active_name = active_name
	hd.description = description
	hd.person_id = person_id
	hd.start_date = start_date
	hd.end_date = end_date
	hd.statu="-1"
	hd.con_pass=con_pass
	hd.createtime = ts1
	hd.b_delete = 0
	hd.hd_type = hd_type

	local ok, err = ssdb:hset("qyjh_hd", hd_id, cjson.encode(hd))
	if not ok then
	   say("{\"success\":false,\"info\":\""..err.."\"}")
	   return
	else
		say("{\"success\":true,\"hd_id\":\""..hd_id.."\",\"name\":\""..active_name.."\",\"info\":\"活动创建成功！\"}")
	end
	--*********************
	
else
	say("{\"success\":false,\"info\":\"连接高百特创建活动失败！\"}")
    return
end
--跟告白特对接结束


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
