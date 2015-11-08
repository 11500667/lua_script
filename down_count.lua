local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源ID
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int = args["resource_id_int"]

--获取TS
local ts = require "resty.TS"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

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

local cjson = require "cjson"

--维护数据库
local sql = "start transaction;"
sql = sql.."update t_resource_base set down_count=IFNULL(down_count,0)+1 where RESOURCE_ID_INT="..resource_id_int..";"
sql = sql.."update t_resource_info set down_count=IFNULL(down_count,0)+1,update_ts= "..ts.getTs().." where RESOURCE_ID_INT = "..resource_id_int..";"
sql = sql.."update t_resource_my_info set down_count=IFNULL(down_count,0)+1,update_ts="..ts.getTs().." where RESOURCE_ID_INT = "..resource_id_int..";"
sql = sql.."update t_sjk_paper_info set down_count=IFNULL(down_count,0)+1,update_ts="..ts.getTs().." where RESOURCE_INFO_ID="..resource_id_int..";"
sql = sql.."select id from t_sjk_paper_info where RESOURCE_INFO_ID="..resource_id_int..";"
sql = sql.."select id from t_resource_info where RESOURCE_ID_INT="..resource_id_int..";"
sql = sql.."select id from t_resource_my_info where RESOURCE_ID_INT="..resource_id_int..";"
sql = sql.."commit;"
local res, err, errno, sqlstate = db:query(sql)
if not res then
	ngx.say("{\"success\":false,\"info\":\""..err.."\"}")    
    return
end
local i_count = 1
local paper_id_int = "0"
local resource_info_id = "0"
local resource_my_info_id = "0"
while err == "again" do
    res, err, errno, sqlstate = db:read_result()
	if i_count == 5 then
		for i=1,#res do
			cache:hincrby("paper_"..res[i]["id"],"down_count",1)
		end		
	end
	if i_count == 6 then
		for i=1,#res do
			--cache:hincrby("resource_"..res[i]["id"],"down_count",1)
			ssdb_db:hincr("resource_"..res[i]["id"],"down_count",1)
		end		
	end
	if i_count == 7 then
		for i=1,#res do
			--cache:hincrby("myresource_"..res[i]["id"],"down_count",1)
			ssdb_db:hincr("myresource_"..res[i]["id"],"down_count",1)
		end		
	end
	i_count = i_count+1
    if not res then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}")         
        return
    end
end

ssdb_db:set_keepalive(0,v_pool_size)
cache:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":\"true\"}")











