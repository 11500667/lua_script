#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--会话ID
local chat_id = tostring(ngx.var.arg_chat_id)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--时间截
local ts = tostring(ngx.now()*1000)
--人员的sys_chatid
local sys_chatid = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"sys_chatid")[1]

local strResult = ""

if chat_id=="100" then
    cache:zunionstore("msgTemp_"..cookie_person_id.."_"..ts,3,"msgContent_100","msgContent_"..cookie_identity_id,"msgContent_"..sys_chatid,"weights",1,1,1) 
    local msg_100 = cache:zrevrangebyscore("msgTemp_"..cookie_person_id.."_"..ts,"+inf","-inf","limit","0","20")
    cache:del("msgTemp_"..cookie_person_id.."_"..ts)
    for i=1,#msg_100 do
        strResult = strResult..msg_100[i]..","
    end
else
    local msg = cache:zrevrangebyscore("msgContent_"..chat_id,"+inf","-inf","limit","0","20")
    for i=1,#msg do
        strResult = strResult..msg[i]..","
    end
end
    strResult = string.sub(strResult,0,#strResult-1)
    cache:del("msgTemp_"..cookie_person_id.."_"..ts)
    strResult = string.gsub (strResult, "\n", "")
    strResult = string.gsub (strResult, "\r", "")
    cache:set("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id,ts)
ngx.say("["..strResult.."]")
