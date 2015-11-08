local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取工作室ID
if args["workroom_id"] == nil or args["workroom_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]

--iid
if args["iid"] == nil or args["iid"] == "" then
    ngx.say("{\"success\":false,\"info\":\"iid参数错误！\"}")
    return
end
local iid = args["iid"]

--连接SSDB
local ssdb = require "resty.ssdb"
local db = ssdb:new()
local ok, err = db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接数据库
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

local ts = require "resty.TS"

local info_id = "0"

--local res_exist = tostring(cache:exists("resource_"..iid))
local res_exist = tostring(db:hexists("resource_"..iid,"resource_id_int"))
if res_exist == "1" then
	info_id = iid
	db:hincr("resource_"..iid,"down_count",1)
else
	local infoid_exist = tostring(cache:exists("cloud_resource_"..iid))	
	if infoid_exist == "1" then
		local resource_info_id = cache:hget("cloud_resource_"..iid,"resource_info_id")
		info_id = resource_info_id
		db:hincr("resource_"..resource_info_id,"down_count",1)
	end
end


local sql = "update t_resource_info set down_count=IFNULL(down_count,0)+1,update_ts= "..ts.getTs().." where id="..info_id..";"
local res, err, errno, sqlstate = mysql_db:query(sql)
if not res then
	ngx.say("{\"success\":false,\"info\":\""..err.."\"}")    
    return
end

db:hincr("resource_"..info_id,"down_count",1)


--下载次数+1
db:hincr("workroom_tj_"..workroom_id,"down_count") 

--更新记录统计json的TS值
local  tj_ts = math.random(1000000)..os.time()
db:set("workroom_tj_ts_"..workroom_id,tj_ts)

--放回到SSDB连接池
db:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":ture}")
