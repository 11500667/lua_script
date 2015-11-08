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

--类型名称
if args["type_name"] == nil or args["type_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_name参数错误！\"}")
    return
end
local type_name = args["type_name"]

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

mysql_db:query("UPDATE t_base_type SET type_name = '"..type_name.."' WHERE id="..id)

mysql_db:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

