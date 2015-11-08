#ngx.header.content_type = "text/plain;charset=utf-8"

local chatid = tostring(ngx.var.arg_id)
if chatid == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有chatid参数！\"}")
    return
end
local chatid2 = tostring(ngx.var.arg_sid)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获取一个两位随机数
local r = string.sub(math.random(),5,6)
--生成一个临时的有序集合key
local temp_key = os.time()+r

local msgInfo = cache:zrange("msg_"..chatid,0,-1,"withscores")
for i=1,#msgInfo,2 do
    local set_value = msgInfo[i]
    local set_score = msgInfo[i+1]
    cache:zadd(temp_key,set_score,set_value)
end

if chatid=="1" then
    if chatid2~="nil" then
	local msgInfo2 = cache:zrange("msg_"..chatid2,0,-1,"withscores")
	if #msgInfo2~=0 then
	    for i=1,#msgInfo2,2 do
		local set_value2 = msgInfo[i]
    		local set_score2 = msgInfo[i+1]
		cache:zadd(temp_key,set_score2,set_value2)
	    end
	end
    end
end

local msgInfo_f = cache:zrange(temp_key,0,-1)
cache:del(temp_key)

local result=""

for i=1,#msgInfo_f do
    result = result..msgInfo_f[i]..","
end
result = string.sub(result,0,#result-1)
ngx.say("{\"success\":true,\"msg_List\":["..result.."]}")

