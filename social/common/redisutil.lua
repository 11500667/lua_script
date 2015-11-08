local redis = require "resty.redis"
local RedisUtil = {}

local function initRedis()
    local redis = redis:new()
    local ok, err = redis:connect(v_redis_ip,v_redis_port)
    if not ok then
        return false
    end
    ngx.ctx[RedisUtil] = redis
    return ngx.ctx[RedisUtil] ;
end

function RedisUtil:getDb()
   return ngx.ctx[RedisUtil] or initRedis()
end
function RedisUtil:keepalive()
    if ngx.ctx[RedisUtil] then
        ngx.ctx[RedisUtil]:set_keepalive(0, v_pool_size)
        ngx.ctx[RedisUtil] = nil
    end
end

return RedisUtil;
