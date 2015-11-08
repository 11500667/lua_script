local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--ID
if args["batch_id"] == nil or args["batch_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"id��������\"}")
    return
end
local batch_id = args["batch_id"]

--���״̬ 2��δͨ�� 3��ͨ��
if args["status"] == nil or args["status"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"status��������\"}")
    return
end
local status = args["status"]

--����mysql���ݿ�
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
mysql_db:query("UPDATE t_rating_resource SET resource_status = "..status.." WHERE id in ("..batch_id..")")
ngx.log(ngx.ERR,"UPDATE t_rating_resource SET resource_status = "..status.." WHERE id in ("..batch_id..")")
local result = {} 
result["success"] = true

--�Ż����ӳ�
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))