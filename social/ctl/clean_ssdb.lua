--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/6/24
-- Time: 8:58
-- To change this template use File | Settings | File Templates.
--
local say = ngx.say
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local file = io.open("/tmp/keys.log", 'r')
local keymethod_t = {}
for line in file:lines() do
    local keymethod_temp = {}
    local s =  split(line,",")
    local keys = split(s[1],":")
    local methods = split(s[2],":")
    keymethod_temp.key = keys[2]
    keymethod_temp.method = methods[2]
    table.insert(keymethod_t,keymethod_temp)
end
file:close()
for i=1 , #keymethod_t do
    if keymethod_t[i].method==nil or string.len(keymethod_t[i].method)==0 then
        ssdb:del(keymethod_t[i].key);
    end
    if keymethod_t[i].method=="hset" then
        ssdb:hclear(keymethod_t[i].key)
    end
    if keymethod_t[i].method=="multi_hset" then
        ssdb:hclear(keymethod_t[i].key)
    end
end

ssdb:set_keepalive(0,v_pool_size)

say("ok")