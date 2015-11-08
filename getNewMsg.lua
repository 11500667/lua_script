#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--会话ID
local chat_id = tostring(ngx.var.arg_chat_id)
--最后一次访问ts
--local last_ts = tostring(ngx.var.arg_last_ts)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--最后一次访问ts
local last_ts = cache:get("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id)

local strResult = ""
local newMsg = cache:zrangebyscore("msgContent_"..chat_id,last_ts,"+inf","withscores")
for i=1,#newMsg,2 do
    strResult = strResult..newMsg[i]..","
end
strResult = string.sub(strResult,0,#strResult-1)

cache:set("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id,newMsg[#newMsg]+1)

ngx.say("["..strResult.."]")

