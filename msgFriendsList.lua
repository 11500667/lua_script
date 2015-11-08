#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

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

local temp_key = cookie_person_id..os.time()

--获取系统
local sys_chatid = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"sys_chatid")[1]
local sys_lastts = cache:get("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_100")
if sys_lastts==ngx.null then
    sys_lastts=0
end

local sys_100_count = cache:zcount("msgContent_100",sys_lastts,"+inf")
local sys_identity_count = cache:zcount("msgContent_"..cookie_identity_id,sys_lastts,"+inf")
local sys_syschatid_count = 0
if sys_chatid~=ngx.null then
    sys_syschatid_count = cache:zcount("msgContent_"..sys_chatid,sys_lastts,"+inf")
end

local count_sum = sys_100_count+sys_identity_count+sys_syschatid_count

cache:zadd(temp_key,1,"100,系统,1,"..count_sum..",0")


--获取群组
local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
for i=1,#group_list do
    local b_use = cache:hmget("groupinfo_"..group_list[i],"b_use")[1]
    if b_use=="1" then
        local chat_id = group_list[i]
        local chat_name = cache:hmget("groupinfo_"..group_list[i],"org_name")[1]
        local chat_type = "3"
        local lastts = cache:get("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id)
        if tostring(lastts)=="userdata: NULL" then
	    lastts = tostring(ngx.now()*1000)
        end
        local chat_count = cache:zcount("msgContent_"..chat_id,lastts,"+inf")
        local chat_url = cache:hmget("groupinfo_"..group_list[i],"avatar_url")[1]   
        if tostring(chat_url)=="userdata: NULL" then
	    chat_url = "images/head_icon/group/group6.png"
        end 
        local ts = cache:zrange("msgContent_"..chat_id,-1,-1,"withscores")[2]
        if tostring(ts)=="nil" then
           ts="0"
        end
    
        cache:zadd(temp_key,ts,chat_id..","..chat_name..","..chat_type..","..chat_count..","..chat_url)
    end
end

local strResult = ""

local group_msg = cache:zrevrange(temp_key,0,-1)
for i=1,#group_msg do
   local info = Split(group_msg[i],",")
   strResult = strResult.."{\"chat_id\":\""..info[1].."\",\"chat_name\":\""..info[2].."\",\"chat_type\":\""..info[3].."\",\"chat_count\":\""..info[4].."\",\"chat_url\":\""..info[5].."\"}," 
end

strResult = string.sub(strResult,0,#strResult-1)

cache:del(temp_key)


--获取好友
local chat_list = cache:smembers("chat_"..cookie_person_id)
for i=1,#chat_list do
    local chat_info = cache:hmget("chat_"..cookie_person_id.."_"..chat_list[i],"chat_name","chat_o_person_id","chat_o_identity_id")
    local chat_id = chat_list[i]
    --local chat_name = chat_info[1]
    local chat_name = cache:hmget("person_"..chat_info[2].."_"..chat_info[3],"person_name")[1]
    if chat_name==ngx.null then
	chat_name = "姓名错误！"
    end
    local chat_type = "4"
    local lastts = cache:get("lastaccess_"..cookie_person_id.."_"..cookie_identity_id.."_"..chat_id)
    local chat_count = cache:zcount("msgContent_"..chat_id,lastts,"+inf")
    if tostring(chat_count)=="false" then
        chat_count = 0
    end
    local chat_url = cache:hmget("person_"..chat_info[2].."_"..chat_info[3],"avatar_url")[1]
    if tostring(chat_url)=="userdata: NULL" then
        chat_url = "images/head_icon/person/hh.png"
    end
    local ts = cache:zrange("msgContent_"..chat_id,-1,-1,"withscores")[2]
    if tostring(ts)=="nil" then
       ts="0"
    end
    cache:zadd(temp_key,ts,chat_id..","..chat_name..","..chat_type..","..chat_count..","..chat_url)
end

local aaa = ""
local person_msg = cache:zrevrange(temp_key,0,-1)
for i=1,#person_msg do
   local info = Split(person_msg[i],",")
   strResult = strResult..",{\"chat_id\":\""..info[1].."\",\"chat_name\":\""..info[2].."\",\"chat_type\":\""..info[3].."\",\"chat_count\":\""..info[4].."\",\"chat_url\":\""..info[5].."\"}"
end

cache:del(temp_key)

ngx.say("["..strResult.."]")

