local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

local tag = tostring(ngx.var.arg_tag)
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
--人员的sys_chatid
local sys_chatid = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"sys_chatid")[1]
--时间截
local ts = tostring(ngx.now()*1000)

local now = ngx.time();

--最后一次访问ts
local last_ts = cache:get("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id)

while true do

    --ngx.sleep(1)

    local old_tag = cache:get("msgLongPollTag_"..cookie_person_id)
    if old_tag~=tag then
	ngx.exit(ngx.HTTP_SPECIAL_RESPONSE)
	break
    end

    local strResult = ""

    local newMsg = ""
    if chat_id=="100" then
	cache:zunionstore("msgTemp_"..cookie_person_id.."_"..ts,3,"msgContent_100","msgContent_"..cookie_identity_id,"msgContent_"..sys_chatid,"weights",1,1,1)
	newMsg = cache:zrangebyscore("msgTemp_"..cookie_person_id.."_"..ts,last_ts,"+inf","withscores")
	cache:del("msgTemp_"..cookie_person_id.."_"..ts)
    else
	newMsg = cache:zrangebyscore("msgContent_"..chat_id,last_ts,"+inf","withscores")
    end

    
    for i=1,#newMsg,2 do
        strResult = strResult..newMsg[i]..","
    end

    strResult = string.sub(strResult,0,#strResult-1)
    if #strResult~=0 then
	cache:set("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id,newMsg[#newMsg]+1)
	--cache:set("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id,ts)
	ngx.say("["..strResult.."]")
	ngx.exit(ngx.HTTP_OK)
    end

    

    if ngx.time()-now>10 then
        ngx.say("["..strResult.."]")
        ngx.exit(ngx.HTTP_OK)
    end


    ngx.sleep(0.5)

end

