-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 成员的基础接口
-- 日期：2015年8月4日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local ssdblib = require "resty.ssdb"
local cjson   = require "cjson";
local _SSDBUtil = { autoKeepAlive = true }

local metaTable = { __index = _SSDBUtil };

---------------------------------------------------------------------------

local function initSsdb()
    local ssdb    = ssdblib:new()
    local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
    if not ok then
        return false
    end
    ngx.ctx[_SSDBUtil] = ssdb
    return ngx.ctx[_SSDBUtil] ;
end

---------------------------------------------------------------------------

function _SSDBUtil:getDb()
   return ngx.ctx[_SSDBUtil] or initSsdb()
end

---------------------------------------------------------------------------

function _SSDBUtil:keepAlive()
    if ngx.ctx[_SSDBUtil] then
        ngx.ctx[_SSDBUtil]:set_keepalive(0, v_pool_size)
        -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [keepAlive()] -> 将SSDB连接归还连接池");
        ngx.ctx[_SSDBUtil] = nil
    end
end

---------------------------------------------------------------------------

function _SSDBUtil:setAutoKeepAlive(flag)
    if flag ~= true and flag ~= false then
        return;
    end
    _SSDBUtil.autoKeepAlive = flag;
end

---------------------------------------------------------------------------

function _SSDBUtil._keepAlive(self)
    if self.autoKeepAlive then
        self:keepAlive();
    end
end

---------------------------------------------------------------------------

function _SSDBUtil.newInstance(self, autoKeepAlive)
    return setmetatable({
            autoKeepAlive = autoKeepAlive
        }, metaTable);
end

-- ----------------------------------------------------------------------------------
-- 函数描述： 对应ssdb的get命令
-- 日    期： 2015年8月4日
-- 参    数： name 缓存的name
-- 返 回 值： 如果有对应的缓存，则返回对应的值； 如果找不到对应的缓存，则返回false；
-- ----------------------------------------------------------------------------------
function _SSDBUtil.get(self, name)
    
    ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [incr] -> 参数：name: [", name, "]");
    local ssdb        = self:getDb();
    local result, err = ssdb: get(name);
    ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [incr] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    self:_keepAlive();
    if not result then
        return false;
    else
        return result[1];
    end
end

-- ----------------------------------------------------------------------------------
-- 函数描述： 对应ssdb的get命令
-- 日    期： 2015年8月4日
-- 参    数： name 缓存的name
-- 返 回 值： 如果有对应的缓存，则返回对应的值； 如果找不到对应的缓存，则返回false；
-- ----------------------------------------------------------------------------------

function _SSDBUtil.incr(self, name)
    
    -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [incr] -> 参数：name: [", name, "]");
    local ssdb   = self:getDb();
    local result, err = ssdb: incr(name);
    -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [incr] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    self:_keepAlive();
    if not result then
        return false;
    else
        return result[1];
    end
end

---------------------------------------------------------------------------

function _SSDBUtil.hset(self, name, key, value)
    
    -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [hset] -> 参数：name: [", name, "], key: [", key, "], value: [", value, "]");
    local ssdb   = self:getDb();
    local result, err = ssdb: hset(name, key, value);
    self:_keepAlive();
    if not result then
        -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [hset] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    end
    return result;
end

---------------------------------------------------------------------------

function _SSDBUtil.hdel(self, name, key)
    
    -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [hdel] -> 参数：name: [", name, "], key: [", key, "]");
    local ssdb   = self:getDb();
    local result, err = ssdb: hdel(name, key);
    self:_keepAlive();
    if not result then
        -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [hdel] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    end
    return result;
end

---------------------------------------------------------------------------

function  _SSDBUtil.multi_hset(self, name, kvTable)
    local cjson = require "cjson";
    -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [hset] -> 参数：name: [", name, "], kvTable: [", cjson.encode(kvTable), "]");
    local ssdb = self:getDb();

    local paramTable = {};    
    for k,v in pairs(kvTable) do
        table.insert(paramTable, k);
        table.insert(paramTable, v);
    end

    local result, err = ssdb: multi_hset(name, unpack(paramTable));
    self:_keepAlive();
    if not result then
        -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [multi_hset] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    end

    return result;
end

---------------------------------------------------------------------------

function  _SSDBUtil.multi_hget(self, name, ...)
    local  keys   = {...};
    local  ssdb   = self:getDb();
    local  result, err = ssdb: multi_hget(name, unpack(keys));
    self:_keepAlive();
    if not result then
        -- ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [multi_hget] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    end

    return result;
end

---------------------------------------------------------------------------

function  _SSDBUtil.multi_hget_hash(self, name, ...)
    local  keys   = {...};
    local  ssdb   = self:getDb();
	ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [hset] -> 参数：name: [", name, "], kvTable: [", cjson.encode(keys), "]");
    local  result, err = ssdb: multi_hget(name, unpack(keys));
    ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [multi_hget] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
    self:_keepAlive();
    if not result then
        ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [multi_hget] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
        return false;
    end

    local tableRes = {};
    for index = 1, #keys do
        tableRes[keys[index]] = result[index*2];
    end
    ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [multi_hget] -> 返回的结果：[", cjson.encode(tableRes), "]");
    return tableRes;
end

-- ----------------------------------------------------------------------------------
-- 以下ssdb中的存储类型【 SORT SET】所对应的函数
-- ----------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------
-- 函数描述： 对应ssdb的zset命令
-- 日    期： 2015年8月31日
-- 参    数： name  缓存的name
-- 参    数： key   缓存的值
-- 参    数： score 缓存的分数
-- 返 回 值： 保存成功返回true， 保存失败返回false
-- ----------------------------------------------------------------------------------
function  _SSDBUtil.zset(self, name, key, score)
    local  ssdb   = self:getDb();
    local  result, err = ssdb: zset(name, key, score);
    ngx.log(ngx.ERR, "\n\n[sj_log] -> [SSDBUtil] -> \nzset函数， \nname:[", name, "], \nkey:[", key, "], \nscore: [", score, "], \n---------- \nresult:[", encodeJson(result), "], \nerr:[", err, "]\n\n");
    self:_keepAlive();
    if not result then
        ngx.log(ngx.ERR, "[sj_log] -> [SSDBUtil] -> [multi_hget] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
        return false;
    end
    
    return result;
end


---------------------------------------------------------------------------
return _SSDBUtil;