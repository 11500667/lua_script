#根据组织ID和学段ID获取班级 by huyue 2015-07-08
local say = ngx.say
local cjson = require "cjson"
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

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
local org_id;
if args["org_id"] == nil or args["org_id"]=="" then
	org_id = tostring(ngx.var.cookie_background_bureau_id);

else 
	org_id = tostring(args["org_id"]);
end


local stage_id = args["stage_id"];


local query_sql = "SELECT t1.CLASS_ID,t1.CLASS_NAME FROM T_BASE_CLASS t1  WHERE t1.ORG_ID ="..org_id.." AND STAGE_ID = "..stage_id;

ngx.log(ngx.ERR,query_sql);
local rows, err, errno, sqlstate = mysql_db:query(query_sql);
if not rows then
	ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
	return;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
local classArray = {}
for i=1,#rows do
	local info = {};
	info["CLASS_ID"] = rows[i]["CLASS_ID"];									--班级ID
	info["CLASS_NAME"] = rows[i]["CLASS_NAME"];								--班级name
	table.insert(classArray, info);
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
local classListJson = {};
classListJson.success    = true;

classListJson.list_class = classArray;
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(classListJson);
say(responseJson);
mysql_db:set_keepalive(0,v_pool_size);
