local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

--学科
local subject_id = tostring(ngx.var.arg_subject_id)
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local content = cache:get("currentpackage_"..cookie_person_id.."_"..subject_id)
local results = "{}"
if content~=ngx.null then
    results = ngx.decode_base64(content)
end
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":true,\"content\":"..results.."}")
