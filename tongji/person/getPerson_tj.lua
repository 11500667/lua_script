local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--subject_id参数 科目ID
if args["subject_id"] == nil or args["subject_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
	return
end
local subject_id = args["subject_id"]

--system_id参数  1：资源 2：试题  3：试卷  4：备课  5：微课
if args["system_id"] == nil or args["system_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"system_id参数错误！\"}")
	return
end
local system_id = args["system_id"]

--person_id参数 人员ID
if args["person_id"] == nil or args["person_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"person_id参数错误！\"}")
	return
end
local person_id = args["person_id"]

local cjson = require "cjson"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.print("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local r_type = {}
--判断是哪种系统，返回类型
if system_id == "1" then	
	local type_res = cjson.decode(cache:get("base_mediatype"))
	for i=1,#type_res do
		local type_tab = {}
		type_tab["id"] = type_res[i].id
		type_tab["name"] = type_res[i].media_type
		r_type[i] = type_tab
	end	
elseif system_id == "2" then
	local qt_id_list = cache:smembers("qt_id_list_"..subject_id)
	if #qt_id_list~=0 then
		for i=1,#qt_id_list do
			local type_tab = {}
			local qt_info = cache:hmget("qt_list_"..subject_id.."_"..qt_id_list[i],"qt_id","qt_name")
			type_tab["id"] = qt_info[1]
			type_tab["name"] = qt_info[2]
			r_type[i] = type_tab
		end
	end	
elseif system_id == "3" then	
	r_type = {{id="1",name="格式化试卷"},{id="2",name="非格式化试卷"}}
elseif system_id == "4" then
	local res = ngx.location.capture("/dsideal_yy/ypt/type/getTypeList?system_id=4")
	r_type = cjson.decode(res.body).list
	table.insert(r_type,{id="1",type_name="资源包"})
	--r_type = {{id="1",name="资源包"},{id="2",name="word"},{id="3",name="ppt"},{id="4",name="教学平台课件"},{id="5",name="视频"}}
else
	r_type = {{id="1",name="问题/任务布置"},{id="2",name="讲解类知识学习"},{id="3",name="认知类知识学习"},{id="4",name="探究类知识学习"},{id="5",name="试题剖析与指导"},{id="6",name="体系梳理与提升"}}
	--r_type = {{id="1",name="知识点概念精讲"},{id="2",name="例题精讲"},{id="3",name="学生相关错题整理"},{id="4",name="学生补救分层练习"}}
end

--标头
local head_tab = {}
--上传
local shangchuan = {}
--收藏
local shoucang = {}
--共享
local gongxiang = {}
--推荐
local tuijian = {}
--评论
local pinglun = {}


for i=1,#r_type do
	--标头
	--head_tab[i] = r_type[i].name
	
	if  system_id == "4" then
			head_tab[i] = r_type[i].type_name
	else
			head_tab[i] = r_type[i].name
	end
	--上传
	shangchuan[i] = "0"
	local str_shangchuanCount =  ssdb_db:hget("tj_person_"..subject_id.."_"..system_id.."_"..r_type[i].id.."_"..person_id,"shangchuanCount")[1]	
	if str_shangchuanCount ~= "" then
		shangchuan[i] = str_shangchuanCount
	end
	--收藏
	shoucang[i] = "0"
	local str_shoucangCount =  ssdb_db:hget("tj_person_"..subject_id.."_"..system_id.."_"..r_type[i].id.."_"..person_id,"shoucangCount")[1]
	if str_shoucangCount ~= "" then
		shoucang[i] = str_shoucangCount
	end
	--共享
	gongxiang[i] = "0"
	local str_gongxiangCount =  ssdb_db:hget("tj_person_"..subject_id.."_"..system_id.."_"..r_type[i].id.."_"..person_id,"gongxiangCount")[1]
	if str_gongxiangCount ~= "" then
		gongxiang[i] = str_gongxiangCount
	end
	--推荐
	tuijian[i] = "0"
	local str_tuijianCount =  ssdb_db:hget("tj_person_"..subject_id.."_"..system_id.."_"..r_type[i].id.."_"..person_id,"tuijianCount")[1]
	if str_tuijianCount ~= "" then
		tuijian[i] = str_tuijianCount
	end
	--评论
	pinglun[i] = "0"
	local str_pinglunCount =  ssdb_db:hget("tj_person_"..subject_id.."_"..system_id.."_"..r_type[i].id.."_"..person_id,"pinglunCount")[1]
	if str_pinglunCount ~= "" then
		pinglun[i] = str_pinglunCount
	end
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
result["attr_title"] = head_tab
result["attr_shangchuan"] = shangchuan
result["attr_shoucang"] = shoucang
result["attr_gongxiang"] = gongxiang
result["attr_tuijian"] = tuijian
result["attr_pinglun"] = pinglun

ngx.print(tostring(cjson.encode(result)))





















