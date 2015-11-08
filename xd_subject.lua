--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local res,err = cache:get("xd_subject")
if not res then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
ngx.say("{\"success\":\"true\","..res.."}")
