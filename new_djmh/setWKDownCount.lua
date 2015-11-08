local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--微课ID
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end
local id = args["id"]

local myTs = require "resty.TS"
local currentTS = myTs.getTs();

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

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end



local wkds_id_int_res = mysql_db:query("select wkds_id_int FROM t_wkds_info WHERE id= "..id)

local info_ids = mysql_db:query("select id FROM t_wkds_info WHERE wkds_id_int= "..wkds_id_int_res[1]["wkds_id_int"])

for i=1,#info_ids do
	local id = info_ids[i]["id"]
	mysql_db:query("UPDATE t_wkds_info SET download_count = download_count+1,update_ts="..currentTS.." WHERE id= "..id)
	redis_db:hincrby("wkds_"..id,"download_count",1)
end





local result = {} 
result["success"] = true

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))


