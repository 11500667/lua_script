--[[
创建联盟
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

local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
if not name or len(name) == 0 or
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

--get id
local t_league_id = ssdb:incr("league_pk")
local league_id = t_league_id[1]

local league = {}
league.league_id = league_id
league.name = name
league.description = description
league.logo_url = logo_url

--save
local ts = os.date("%Y%m%d%H%M%S")
ssdb:hset("league_leagues", league_id, cjson.encode(league))
	--for paging
ssdb:zset("league_leagues_sorted", league_id, ts)

--return result
local rr = {}
rr.success = true
rr.league_id = league_id
rr.name = name
rr.info = "保存成功!"

say(cjson.encode(rr))

ssdb:set_keepalive(0,v_pool_size)