--[[
Lua接口，删除日程
@Author feiliming
@Date   2015-2-13
]]

local say = ngx.say
local len = string.len

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--args
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

local schedule_type = args["schedule_type"]
local schedule_type_id = args["schedule_type_id"]
local schedule_id = args["schedule_id"]

if not schedule_type or len(schedule_type) == 0
	or not schedule_type_id or len(schedule_type_id) == 0
	or not schedule_id or len(schedule_id) == 0 then
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

--del
local result, err = ssdb:hdel("space_schedule_"..schedule_type.."_"..schedule_type_id, schedule_id)
local rr = {}
if not result then
	rr.success = false
	rr.info = err
else
	rr.success = true
	rr.info = "成功!"
end

say(cjson.encode(rr))

--
ssdb:set_keepalive(0,v_pool_size)