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

local groupId = tostring(ngx.var.arg_groupId)
--判断是否有groupId参数
if groupId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有groupId参数！\"}")
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

local gbr = cache:smembers("gbr_"..groupId.."_"..bureau_id)

local cjson = require "cjson"
local result = cjson.encode(gbr)

ngx.say("{\"orgIds\":"..result.."}")

