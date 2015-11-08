local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--resource_id_int
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int = args["resource_id_int"]

--scheme_id_int
if args["scheme_id_int"] == nil or args["scheme_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id_int参数错误！\"}")
    return
end
local scheme_id_int = args["scheme_id_int"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--获取该资源的stage_id和subject_id
local res = db:query("select stage_id,subject_id from t_resource_scheme where scheme_id="..scheme_id_int)
local stage_id = res[1]["stage_id"]
local subject_id = res[1]["subject_id"]

ssdb_db:zdel("resource_sort_"..stage_id,resource_id_int)
ssdb_db:zdel("resource_sort_"..stage_id.."_"..subject_id,resource_id_int)

ssdb_db.hdel("resource_sort_infoid_idint_"..stage_id,resource_id_int)
ssdb_db:hdel("resource_sort_infoid_idint_"..stage_id.."_"..subject_id,resource_id_int)	

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)






