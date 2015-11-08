
local cjson = require "cjson"
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

ngx.log(ngx.ERR,"#1111111111########"..tostring(ngx.today()).."#1111111111########")

local result = {} 
result["success"] = true

local person_id = "cba"
local rating_id = "1111111"

local voteCount = redis_db:hget("vote_"..rating_id,person_id)

local voteCount = redis_db:hget("vote_"..rating_id,person_id)
if voteCount ~= ngx.null then
	if tonumber(voteCount)>5 then
		result["success"] = false
	end
end

redis_db:hincrby("vote_"..rating_id,person_id,1)

if result["success"] == true then
	ngx.log(ngx.ERR,"#2#2#2#2##2#2#2#2##2#2#2#2##2#2#2#2##2#2#2#2##2#2#2#2#")
else
	ngx.log(ngx.ERR,"#1#1##1#1##1#1##1#1##1#1##1#1##1#1##1#1##1#1##1#1#")
end

cjson.encode_empty_table_as_object(false);
ngx.log(ngx.ERR,"#1#1#1#1#1#"..cjson.encode(result).."#1#1#1#1#1#")

local resource_info = mysql_db:query("SELECT resource_info_id,person_name,bureau_name,ts FROM t_rating_resource WHERE rating_id = 111111")


ngx.log(ngx.ERR,"######"..tostring(resource_info[1]).."######")