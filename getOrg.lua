#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有Cookie参数person_id！\"}")
    return
end

local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有Cookie参数identity_id！\"}")
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
local bureau_id = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
local bureau_tree = cache:get("bureau_"..bureau_id)
ngx.say(bureau_tree)
