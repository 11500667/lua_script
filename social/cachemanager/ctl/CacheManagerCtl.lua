-- 缓存管理
-- Created by IntelliJ IDEA.
-- User: zhanghai
-- Date: 2015/9/29 0029
-- Time: 上午 9:10
-- To change this template use File | Settings | File Templates.
--
ngx.header.content_type = "text/plain";
local web = require("social.router.web")
local cjson = require "cjson"
local request = require("social.common.request")
local no_permission_context = ngx.var.path_uri  --无权限的context.
local log = require("social.common.log")
local SsdbUtil = require("social.common.ssdbutil")

--查询hget值
local function hash_query()
    local name = request:getStrParam("name", true, true)
    local key = request:getStrParam("key",true,true);
    local db = SsdbUtil:getDb()
    local result = db:hget(name, key);
    ngx.print(cjson.encode(result))
end

--设置hset
local function hash_set()
    local db = SsdbUtil:getDb()
    local name = request:getStrParam("name", true, true)
    local key = request:getStrParam("key",true,true);
    local value = request:getStrParam("value",true,true)
    local r = db:hset(name, key, value);
    ngx.print(cjson.encode(r))
end
--设置hash _multi
local function hash_multi_set()
    local name = request:getStrParam("name", true, true)
    local keys = request:getStrParam("keys",true,true);
    local values = request:getStrParam("values",true,true)
    local db = SsdbUtil:getDb()
    local keytable = Split(keys,",");
    local valuestable = Split(values,",");
    local ta = {}
    for i = 1, #keytable do
        local t = {[keytable[i]]=valuestable[i] }
        table.insert(ta,t);
    end
    local status, err = db:multi_hset(name,ta)
    ngx.print(cjson.encode(status))
end


--查询hash _multi
local function hash_multi_get()
    local name = request:getStrParam("name", true, true)
    local keys = request:getStrParam("keys",true,true);

    local db = SsdbUtil:getDb()
    local keytable = Split(keys,",");
    local t = {}
    for i=1,#keytable do
        table.insert(t,keytable[i])
    end
    local result = db:multi_hget(name,unpack(t));
    ngx.print(cjson.encode(result))
end

--查询get
local function get()
    local key = request:getStrParam("key",true,true);
    local db = SsdbUtil:getDb()
    local result = db:get(key);
    ngx.print(cjson.encode(result))
end


--设置set
local function set()
    local key = request:getStrParam("key",true,true);
    local value = request:getStrParam("value",true,true);
    local db = SsdbUtil:getDb()
    local status, err = db:set(key,value);
    ngx.print(cjson.encode(status))
end


local function hash_all()
    local name = request:getStrParam("name",true,true);
    local db = SsdbUtil:getDb()
    local result = db:hgetall(name);
    ngx.print(cjson.encode(result))
end


-- 配置url.
-- 按功能分
local urls = {
    no_permission_context .. '/hget', hash_query,
    no_permission_context .. '/hset', hash_set,
    no_permission_context .. '/m_hset', hash_multi_set,
    no_permission_context .. '/m_hget', hash_multi_get,
    no_permission_context .. '/hall', hash_all,
    no_permission_context .. '/get', get,
    no_permission_context .. '/set', set,
}
local app = web.application(urls, nil)
app:start()