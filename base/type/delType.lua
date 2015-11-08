local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--id
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"id参数错误！\"}")
    return
end
local id = args["id"]

if args["system_id"] == nil or args["system_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"system_id参数错误！\"}")
    return
end
local system_id = args["system_id"]


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
local sql ="";
if system_id == "4" then
   sql  = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query='filter=bk_type,"..id.."';";
elseif system_id == "3" then
  sql  = "SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse  WHERE query='filter=PAPER_APP_TYPE,"..id.."';";
end
local isExist = mysql_db:query(sql);

local result = {}

if isExist[1] ~= nil then
	result["success"] = true
	result["info"] = "该类型正在使用中，无法删除！"
	result["b_use"] = "1";
else	
	mysql_db:query("UPDATE t_base_type SET b_use = 2 WHERE id="..id)
	result["success"] = true
	result["b_use"] = "0";
end

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

