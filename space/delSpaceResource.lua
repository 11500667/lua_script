local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if args["ids"] == nil or args["ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"ids参数错误！\"}")
    return
end
local ids = args["ids"]

local person_id = tostring(ngx.var.cookie_person_id)

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

--删除资源
mysql_db:query("DELETE FROM t_resource_info WHERE  person_id="..person_id.." AND res_type=10 AND id IN("..ids..")")

local infoids = Split(ids,",")
for i=1,#infoids do
    mysql_db:query("INSERT INTO sphinx_del_info (del_index_id) VALUES ("..infoids[i]..")")
end

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true}")
