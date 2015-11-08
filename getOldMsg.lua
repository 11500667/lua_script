#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end



--会话ID
local chat_id = tostring(ngx.var.arg_chat_id)
--最后一条消息的ts
local lastMsg_ts = tostring(ngx.var.arg_lastMsg_ts)
--人员的sys_chatid
local sys_chatid = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"sys_chatid")[1]
--时间截
local ts = tostring(ngx.now()*1000)


local strResult = ""
local old_msg = ""

if chat_id=="100" then
    cache:zunionstore("msgTemp_"..cookie_person_id.."_"..ts,3,"msgContent_100","msgContent_"..cookie_identity_id,"msgContent_"..sys_chatid,"weights",1,1,1)
    old_msg = cache:zrevrangebyscore("msgTemp_"..cookie_person_id.."_"..ts,"("..lastMsg_ts,"-inf","limit","0","3")
else
    old_msg = cache:zrevrangebyscore("msgContent_"..chat_id,"("..lastMsg_ts,"-inf","limit","0","3")
end
for i=1,#old_msg do
    strResult = strResult..old_msg[i]..","
end
strResult = string.sub(strResult,0,#strResult-1)
cache:del("msgTemp_"..cookie_person_id.."_"..ts)
ngx.say("["..strResult.."]")
