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

-- -----------------------------------------------------------------------------------
-- 函数描述： String类型对应的函数：set
-- 作    者： 申健        2015-08-31
-- 参    数： key   缓存的key
-- 参    数： val   缓存的值
-- 返 回 值： 应用类型名称
-- -----------------------------------------------------------------------------------
function _CacheUtil:set(key, val)
	local cache = self:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: set(key, val);
	ngx.log(ngx.ERR, "\n\n[sj_log] -> [CacheUtil] -> set函数， key:[", key, "], value: [", val, "], ---------- result:[", encodeJson(result), "], err:[", err, "]\n\n");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		return false;
	end
	return result;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 设置缓存的存活时间
-- 作    者： 申健       2015-08-31
-- 参    数： key       缓存的key
-- 参    数： seconds   剩余的时间（单位秒）
-- 返 回 值： 应用类型名称
-- -----------------------------------------------------------------------------------
function _CacheUtil:expire(key, seconds)
	local cache = self:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: expire(key, seconds);
	ngx.log(ngx.ERR, "\n\n[sj_log] -> [CacheUtil] -> expire函数， key:[", key, "], value: [", val, "], ---------- result:[", encodeJson(result), "], err:[", err, "]\n\n");
	_CacheUtil:keepConnAlive(cache);
	return (result == 1 and true) or false;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： String类型对应的函数：get
-- 作    者： 申健   2015-12-25
-- 参    数： key    缓存的key
-- 返 回 值： 缓存中key对应的值，如果获取不到时，返回false；
-- -----------------------------------------------------------------------------------
function _CacheUtil:get(key)
	local cache = self:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: get(key);
	ngx.log(ngx.ERR, "\n\n[sj_log] -> [CacheUtil] -> get函数， key:[", key, "], ---------- result:[", result, "], err:[", err, "]\n\n");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		return false, err;
	else
		if result ~= nil and result ~= ngx.null then
			return result;
		else
			return false, err;
		end
	end
end

function _CacheUtil:incr(key)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: incr(key);
	return result;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： String类型对应的函数：del
-- 作    者： 申健        2015-08-31
-- 参    数： key   待删除的缓存的key
-- 返 回 值： 应用类型名称
-- -----------------------------------------------------------------------------------
function _CacheUtil:del(key)
	local cache = self:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: del(key);
	ngx.log(ngx.ERR, "\n\n[sj_log] -> [CacheUtil] -> del函数， key:[", key, "] ---------- result:[", encodeJson(result), "], err:[", err, "]\n\n");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		return false;
	end
	return result;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 判断key是否存在
-- 作    者： 申健   2015年12月3日
-- 参    数： key    待查询的缓存的key
-- 返 回 值： 存在true，不存在返回false
-- -----------------------------------------------------------------------------------
function _CacheUtil:exists(key)
	local cache = self:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: exists(key);
	ngx.log(ngx.ERR, "\n\n[sj_log] -> [CacheUtil] -> exists函数， key:[", key, "] ---------- result:[", encodeJson(result), "], err:[", err, "]\n\n");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		return false;
	end
	local resNum = tonumber(result);
	return (resNum == 1 and true) or false;
end


----------------------------------------------------------------------------------
--[[
	描述： 判断缓存中field是否存在
	参数： key 		缓存的key
	参数： field 	缓存的field的名称
	返回： true 存在，false 不存在
]]
function _CacheUtil:hexists(key, field)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: hexists(key, field);
	_CacheUtil:keepConnAlive(cache);
	if not result then
		return false;
	end
	local resNum = tonumber(result);
	return (resNum == 1 and true) or false;
end
----------------------------------------------------------------------------------
--[[
	描述： 判断缓存中field是否存在
	参数： cache 	缓存对象
	参数： key 		缓存的key
	参数： field 	缓存的field的名称
	返回： true 存在，false 不存在
]]
function _CacheUtil:hexists_cache(cache, key, field)
	local result, err = cache: hexists(key, field);
	if not result then
		return false;
	end
	local resNum = tonumber(result);
	return (resNum == 1 and true) or false;
end
----------------------------------------------------------------------------------
--[[
	描述： 判断缓存中field是否存在
	参数： key 		缓存的key
	参数： field 	缓存的field的名称
	返回： 返回结果字符串，false key或field不存在
]]
function _CacheUtil:hget(key, field)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: hget(key, field);
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> key:[", key, "], field:[", field, "] 的缓存不存在。");
		return false;
	end
	return result;
end

----------------------------------------------------------------------------------
--[[
	描述： 一次从指定HASH类型的缓存中获取多个field对应的值
	参数： key 		缓存的key
	参数： field 	缓存的field的名称
	返回： 返回结果字符串，false key或field不存在
]]
function _CacheUtil:hmget(key, ...)
	local args = {...};

	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: hmget(key, unpack(args));
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取 key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end
	local cjson = require "cjson";
	local resultTab = {};
	for index = 1, #args do
		resultTab[args[index]] = result[index];
	end
	-- ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> key:[", key, "], 查询的返回值：", cjson.encode(result), ", 组织后的返回值：", cjson.encode(resultTab));

	return resultTab;
end
----------------------------------------------------------------------------------

function _CacheUtil:hset(key, field, value)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: hset(key, field, value);
	-- ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> hset -> key:[", key, "], value:[", value, "]，------------ result:[", encodeJson(result), "], err：[", err, "]。");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> hset -> key:[", key, "], value:[", value, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end

	return result;
end
----------------------------------------------------------------------------------

function _CacheUtil:hmset(key, ...)
	local args = {...};

	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: hmset(key, unpack(args));
	-- ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> \nkey:[", key, "], \nfields:[", encodeJson(args), "], \nresult:[", encodeJson(result), "], \nerr : [", err, "] ");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取 key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end

	local resultTab = {};
	for index = 1, #args do
		resultTab[args[index]] = result[index];
	end

	return resultTab;
end

----------------------------------------------------------------------------------

function _CacheUtil:setTable2Hash(key, hashTable)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end
	local valTable = {};
	for hashKey, hashVal in pairs(hashTable) do
		table.insert(valTable, hashKey);
		table.insert(valTable, hashVal)
	end

	local result, err = cache: hmset(key, unpack(valTable));
	-- ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> \nkey:[", key, "], \nfields:[", encodeJson(args), "], \nresult:[", encodeJson(result), "], \nerr : [", err, "] ");
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取 key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end
	return true;
end

----------------------------------------------------------------------------------
--[[
	描述： 判断缓存中field是否存在
	参数： key 		缓存的key
	参数： field 	缓存的field的名称
	返回： 返回结果字符串，false key或field不存在
]]
function _CacheUtil:zrange(key, start, limit)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: zrange(key, start, limit);
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> key:[", key, "], start:[", start, "], limit:[", limit, "] 的缓存不存在。");
		return false;
	end
	return result;
end

----------------------------------------------------------------------------------
--[[
	描述： 将一个或多个 member 元素加入到集合 key 当中，已经存在于集合的 member 元素将被忽略。
		   假如 key 不存在，则创建一个只包含 member 元素作成员的集合。
		   当 key 不是集合类型时，返回一个错误。
	参数： key 		缓存的key
	参数： ... 	    可变参数，需要向Set中添加的一个或多个成员变量
	返回： 成功：被添加到集合中的新元素的数量，不包括被忽略的元素；失败：返回false
]]
function _CacheUtil:sadd(key, ...)
	
	local members = {...};
	local cache   = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: sadd(key,  unpack(members));
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> sadd操作出错，key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end
	return result;
end

----------------------------------------------------------------------------------
--[[
	描述： 判断缓存中field是否存在
	参数： key 		缓存的key
	参数： field 	缓存的field的名称
	返回： 返回结果字符串，false key或field不存在
]]
function _CacheUtil:smembers(key)
	local cache = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: smembers(key);
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end
	return result;
end

----------------------------------------------------------------------------------
--[[
	描述： 从Set的缓存中删除一个或多个成员
	参数： key 		缓存的key
	参数： ... 	    可变参数，需要删除的一个或多个成员变量
	返回： 成功：返回被成功移除的元素的数量，不包括被忽略的元素；失败：返回false
]]
function _CacheUtil:srem(key, ...)
	
	local members = {...};
	local cache   = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: srem(key,  unpack(members));
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> srem操作出错，key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end
	return result;
end

----------------------------------------------------------------------------------
--[[
	描述： 向LIST缓存的左侧推入一条记录
	参数： key 		缓存的key
	参数： ... 	    可变参数，需要删除的一个或多个成员变量
	返回： 成功：返回被成功移除的元素的数量，不包括被忽略的元素；失败：返回false
]]
function _CacheUtil:lpush(key, val)
	
	local cache   = _CacheUtil:getRedisConn();
	if not cache then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> 获取redis连接失败。");
		_CacheUtil:keepConnAlive(cache);
		return false;
	end

	local result, err = cache: lpush(key, val);
	_CacheUtil:keepConnAlive(cache);
	if not result then
		ngx.log(ngx.ERR, "[sj_log] -> [cache_util] -> lpush操作出错，key:[", key, "] 的缓存出错，错误信息：[", err, "]。");
		return false;
	end
	return result;
end

----------------------------------------------------------------------------------

-- 返回DBUtil对象
return _CacheUtil;