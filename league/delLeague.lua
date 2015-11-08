--[[
删除联盟
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

--delete
ssdb:hdel("league_leagues", league_id)
ssdb:zdel("league_leagues_sorted", league_id)

--return result
local rr = {}
rr.success = true
rr.info = "删除成功!"

say(cjson.encode(rr))

ssdb:set_keepalive(0,v_pool_size)