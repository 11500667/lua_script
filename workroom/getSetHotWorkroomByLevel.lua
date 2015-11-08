--[[
获得某个级别(0,1,2,3)下的最热工作室
@Author feiliming
@Date   2015-1-12
]]
local say = ngx.say
local len = string.len

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local level = ngx.var.arg_level
if not level or len(level) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据level查
local limit = 100
local list0 = {}
local z0 = ssdb:zrange("workroom_"..level.."_w_hot", 0, limit)
if z0 and z0[1] and z0[1] ~= "ok" then
	local wids = {}
	for i=1,#z0,2 do
		table.insert(wids, z0[i])
	end
	local w0 = ssdb:multi_hget("workroom_workrooms", unpack(wids))
	if w0 and w0[1] and w0[1] ~= "ok" then
		local order = 1
		for i=1,#w0,2 do
			local w = cjson.decode(w0[i+1])
			w.stage = nil
			w.description = nil
			w.logo_url = nil
			w.region_id = nil
			w.order = order
			order = order + 1
			table.insert(list0, w)
		end
	end
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.list = list0
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)