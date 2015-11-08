--[[
	局部函数：获取Redis连接
]]
local _CacheUtil = {};

function _CacheUtil:getRedisConn()
	
	-- 获取redis链接
	local redis = require "resty.redis"
	local cache = redis:new()
	local ok,err = cache:connect(v_redis_ip,v_redis_port)
	if not ok then
		ngx.print("{\"success\":\"false\",\"info\":\""..err.."\"}")
		return false;
	end
	
	return cache;
end

--[[
	局部函数：将mysql连接归还到连接池
]]
function _CacheUtil:keepConnAlive(cache)
	-- 将redis连接归还到连接池
	local ok, err = cache: set_keepalive(0, v_pool_size)
	if not ok then
		ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
		return false;
	end
	return true;
end

-- _CacheUtil.getDb = getDb;
-- _CacheUtil.keepDbAlive = keepDbAlive;

-- 返回DBUtil对象
return _CacheUtil;