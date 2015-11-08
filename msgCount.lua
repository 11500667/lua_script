#ngx.header.content_type = "text/plain;charset=utf-8"

local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有person_id参数！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有identity_id参数！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--Split方法
local function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
   if not nFindLastIndex then
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    break
   end
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
end
return nSplitArray
end

local chatids = tostring(ngx.var.arg_ids)
--判断是否有identity_id的cookie信息
if chatids == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有chatids参数！\"}")
    return
end

local ids = Split(chatids,",")

local result=""

for i=1,#ids do
    local ts = cache:get("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..ids[i])
    local count = cache:zcount("msg_"..ids[i],ts,"+inf")
    local lastMsg = cache:zrange("msg_"..ids[i],-1,-1)
    result = result.."{\"chat_id\":\""..ids[i].."\",\"msg_count\":\""..count.."\",\"msg_last\":"..lastMsg[1].."},"
end

result = string.sub(result,0,#result-1)

ngx.say("{\"success\":true,\"msg_List\":["..result.."]}")
