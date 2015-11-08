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
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local str_reslut=""
local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
for i=1,#group_list do
    local groupname = cache:hmget("groupinfo_"..group_list[i],"org_name","b_use","source_id")
    if groupname[2]=="1" and groupname[3]=="1" then
        str_reslut = str_reslut.."{\"group_id\":\""..group_list[i].."\",\"group_name\":\""..groupname[1].."\"},"
    end
end

str_reslut = string.sub(str_reslut,0,#str_reslut-1)

ngx.say("{\"success\":true,\"group_List\":["..str_reslut.."]}")

