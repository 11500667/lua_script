local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--pageSize参数
if args["pageSize"] == nil or args["pageSize"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
	return
end
local pageSize = args["pageSize"]

--pageNumber参数
if args["pageNumber"] == nil or args["pageNumber"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
	return
end
local pageNumber = args["pageNumber"]

--column_id参数
if args["column_id"] == nil or args["column_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_id参数错误！\"}")
	return
end
local column_id = args["column_id"]

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

local djmh_news_ts = redis_db:get("djmh_news_ts_"..bureau_id)
local generate_ts = redis_db:get("generate_ts_"..bureau_id)

if djmh_news_ts == ngx.null then
	local uuid =  require "resty.uuid";
	djmh_news_ts = uuid.new();	
	redis_db:set("djmh_news_ts_"..bureau_id,djmh_news_ts)			
end

if generate_ts == ngx.null or djmh_news_ts ~= generate_ts then	

	local  update_ts = math.random(1000000)
	
	redis_db:set("djmh_news_ts_"..bureau_id,update_ts)
	redis_db:set("generate_ts_"..bureau_id,update_ts)

	local regist_id = "-1"
	local res = mysql_db:query("SELECT regist_id FROM t_djmh_news WHERE bureau_id="..bureau_id.." limit 1")
	if #res ~= 0 then
		regist_id = res[1]["regist_id"]
	end

	local res = ngx.location.capture("/dsideal_yy/djmh/getNewsListByRegistId?regist_id="..regist_id.."&pageSize="..pageSize.."&pageNumber="..pageNumber.."&column_id="..column_id.."&random="..math.random(1000))
	local str = res.body
	
	redis_db:set("djmh_news_"..bureau_id,str)	
end

local result = redis_db:get("djmh_news_"..bureau_id)
-- 将mysql连接归还到连接池
mysql_db:set_keepalive(0, v_pool_size);
redis_db:set_keepalive(0, v_pool_size);

ngx.print(result)






