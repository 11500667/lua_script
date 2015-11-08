local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--system_id参数  1：资源 2：试题  3：试卷  4：备课  5：微课
if args["system_id"] == nil or args["system_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"system_id参数错误！\"}")
	return
end
local system_id = args["system_id"]

--bType参数  1：收藏  6：我的上传 7：我的共享
if args["bType"] == nil or args["bType"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bType参数错误！\"}")
	return
end
local bType = args["bType"]

--my_info 的id
if args["id"] == nil or args["id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"id参数错误！\"}")
	return
end
local id = args["id"]

local cookie_person_id = tostring(ngx.var.cookie_person_id)
--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"cookie中未获取到person_id！\"}")
    return
end
local person_id = cookie_person_id

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

local sql = "";

if system_id == "1" then
	sql = mysql_db:query("SELECT resource_type as type_id,subject_id FROM t_resource_my_info WHERE res_type = 1 AND id="..id)
elseif system_id == "2" then
	sql = mysql_db:query("SELECT question_type_id as type_id,t2.subject_id FROM t_tk_question_my_info  T1 INNER JOIN t_resource_scheme T2 ON T1.SCHEME_ID_INT =T2.SCHEME_ID WHERE id = "..id)
elseif system_id == "3" then
	sql = mysql_db:query("SELECT paper_type as type_id,subject_id FROM t_sjk_paper_my_info where id="..id)
elseif system_id == "4" then
	sql = mysql_db:query("SELECT bk_type as type_id,subject_id FROM t_resource_my_info WHERE res_type = 2 AND id="..id)
else
	sql = mysql_db:query("SELECT wk_type as type_id,t2.subject_id FROM t_wkds_info t1 inner join t_resource_scheme t2 on t1.SCHEME_ID=T2.SCHEME_ID where id = "..id)
end

if tostring(#sql) ~= "0" then	
	local subject_id = sql[1]["subject_id"]
	local type_id = sql[1]["type_id"]
	
	local strCount = ""
	
	if tostring(bType) == "1" then
		strCount = "shoucangCount"   
	elseif tostring(bType) == "6" then
		strCount = "shangchuanCount"
	else
		strCount = "gongxiangCount"
	end
	
	ssdb_db:hdecr("tj_person_"..subject_id.."_"..system_id.."_"..type_id.."_"..person_id,strCount)
	ngx.say("{\"success\":\"true\"}")
	
else
	ngx.say("{\"success\":\"false\",\"info\":\"根据id参数未找到数据\"}")
    return
end















