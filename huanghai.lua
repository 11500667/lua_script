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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local bureau_id = redis_db:hget("person_30213_5","xiao")
if bureau_id == ngx.null then
	ngx.print("11111111111");
end
