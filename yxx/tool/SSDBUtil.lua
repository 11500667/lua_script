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
       -- ngx.log(ngx.ERR, "将SSDB连接归还连接池");
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

---------------------------------------------------------------------------

function _SSDBUtil.incr(self, name)
    
    local ssdb   = self:getDb();
    local result, err = ssdb: incr(name);
    self:_keepAlive();
    if not result then
        return false;
    else
        return result[1];
    end
end

---------------------------------------------------------------------------

function _SSDBUtil.hset(self, name, key, value)
    local ssdb   = self:getDb();
    local result, err = ssdb: hset(name, key, value);
    self:_keepAlive();
    if not result then
        ngx.log(ngx.ERR, "结果：[", cjson.encode(result), "], err:[", err, "]");
    end
    return result;
end
---------------------------------------------------------------------------

function _SSDBUtil.hget(self, name, key)
    local ssdb   = self:getDb();
    local result, err = ssdb: hget(name, key);
    self:_keepAlive();
    if not result then
        ngx.log(ngx.ERR, "结果：[", cjson.encode(result), "], err:[", err, "]");
    end
    return result;
end
---------------------------------------------------------------------------

function  _SSDBUtil.multi_hset(self, name, kvTable)
    local cjson = require "cjson";
    --ngx.log(ngx.ERR, " 参数：name: [", name, "], kvTable: [", cjson.encode(kvTable), "]");
    local ssdb = self:getDb();

    local paramTable = {};    
    for k,v in pairs(kvTable) do
        table.insert(paramTable, k);
        table.insert(paramTable, v);
    end

    local result, err = ssdb: multi_hset(name, unpack(paramTable));
    self:_keepAlive();
    if not result then
        ngx.log(ngx.ERR, "结果：[", cjson.encode(result), "], err:[", err, "]");
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
        ngx.log(ngx.ERR, "结果：[", cjson.encode(result), "], err:[", err, "]");
    end

    return result;
end

function  _SSDBUtil.multi_hget_hash(self, name, ...)
    local  keys   = {...};
    local  ssdb   = self:getDb();
    local  result, err = ssdb: multi_hget(name, unpack(keys));
    self:_keepAlive();
    if not result then
        ngx.log(ngx.ERR, "[SSDBUtil] -> [multi_hget] -> 结果：[", cjson.encode(result), "], err:[", err, "]");
        return false;
    end

    local tableRes = {};
    for index = 1, #keys do
        tableRes[keys[index]] = result[index*2];
    end
    return tableRes;
end
---------------------------------------------------------------------------

return _SSDBUtil;