--[[
Lua接口，查询日程
@Author feiliming
@Date   2015-2-14
]]

local say = ngx.say
local len = string.len

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--get args
local schedule_type = ngx.var.arg_schedule_type
local schedule_type_id = ngx.var.arg_schedule_type_id

if not schedule_type or len(schedule_type) == 0 
    or not schedule_type_id or len(schedule_type_id) == 0 then
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

local result, err = ssdb:hscan("space_schedule_"..schedule_type.."_"..schedule_type_id, "", "", 100000)
if not result then
	say("{\"success\":false,\"info\":\"查询失败!\"}")
    return
end
local list = {}
if result and result[1] and result[1] ~= "ok" then
	for i=1,#result,2 do
		local schedule = cjson.decode(result[i+1])
		list[#list + 1] = schedule
	end
end


local rr = {}
rr.success = true
rr.schedule_list = list
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

ssdb:set_keepalive(0,v_pool_size)