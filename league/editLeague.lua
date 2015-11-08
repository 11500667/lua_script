--[[
编辑联盟
@Author feiliming
@Date   2015-1-19
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--get args
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local league_id = args["league_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
if not league_id or len(league_id) == 0 or
    not name or len(name) == 0 or
	not description or len(description) == 0 or
	not logo_url then
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

--base64
description = ngx.encode_base64(description)
name = ngx.encode_base64(name)

--hget
local tl = ssdb:hget("league_leagues", league_id)
if not tl or not tl[1] then
	say("{\"success\":false,\"info\":\"未找到联盟！\"}")
	return
end
local league = cjson.decode(tl[1])
league.league_id = league_id
league.name = name
league.description = description
league.logo_url = logo_url

ssdb:hset("league_leagues", league_id, cjson.encode(league))

--return result
local rr = {}
rr.success = true
rr.info = "保存成功!"

say(cjson.encode(rr))

ssdb:set_keepalive(0,v_pool_size)
