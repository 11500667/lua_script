--[[
前台接口，获得某个级别(0,1,2,3)下的最热工作室，不够的拿访问次数最多的补齐
@Author feiliming
@Date   2015-1-13
]]

local say = ngx.say
local len = string.len

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local level = ngx.var.arg_level
local limit = ngx.var.arg_limit
if not level or len(level) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end
if not limit or len(limit) == 0 then
	limit = 10
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据level查
local list0 = {}
local z0 = ssdb:zrange("workroom_"..level.."_w_hot", 0, limit)
if z0 and z0[1] and z0[1] ~= "ok" then
	local wids = {}
	for i=1,#z0,2 do
		table.insert(wids, z0[i])
	end
	local w0 = ssdb:multi_hget("workroom_workrooms", unpack(wids))
	if w0 and w0[1] and w0[1] ~= "ok" then
		for i=1,#w0,2 do
			local w = cjson.decode(w0[i+1])
			w.stage = nil
			--w.description = nil
			--w.logo_url = nil
			w.region_id = nil
			table.insert(list0, w)
		end
	end
end

--判断补齐,取最新里面的
limit = tonumber(limit)
if #list0 < limit then
	local b0 = ssdb:zrange("workroom_"..level.."_w_new", 0, limit * 2)
	if b0 and b0[1] and b0[1] ~= "ok" then
		local wids = {}
		for i=1,#b0,2 do
			table.insert(wids, b0[i])
		end
		local w0 = ssdb:multi_hget("workroom_workrooms", unpack(wids))
		if w0 and w0[1] and w0[1] ~= "ok" then
			for i=1,#w0,2 do
				if #list0 >= limit then
					break
				end
				local w = cjson.decode(w0[i+1])
				local flag = false
				for j=1,#list0 do
					if tostring(list0[j].workroom_id) == tostring(w.workroom_id) then
						flag = true
						break
					end
				end
				if not flag then
					w.stage = nil
					--w.description = nil
					--w.logo_url = nil
					w.region_id = nil
					table.insert(list0, w)
				end
			end
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