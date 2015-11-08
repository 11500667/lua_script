--[[
根据联盟id查看联盟基本信息
@Author feiliming
@Date   2015-1-19
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--get args
local league_id = ngx.var.arg_league_id

if not league_id or len(league_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--hget
local league = {}
local tl = ssdb:hget("league_leagues", league_id)
if tl and tl[1] and tl[1] ~= "ok" then
	league = cjson.decode(tl[1])
end

--return result
local rr = {}
rr.success = true
rr.league = league

say(cjson.encode(rr))

ssdb:set_keepalive(0,v_pool_size)
