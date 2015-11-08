--[[
新闻通知公告申请注册号
@Author  feiliming
@Date    2015-7-14
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local rt, err = ssdb:incr("social_notice_register_id")
if not rt then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local register_id = rt[1]

--return
local rr = {}
rr.success = true
rr.register_id = tonumber(register_id)

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)