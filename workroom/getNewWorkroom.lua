--[[
获取最新工作室
@Author  feiliming
@Date    2015-1-8
]]

local say = ngx.say
local len = string.len

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local limit = ngx.var.arg_limit
if not limit or len(limit) == 0 then
	limit = 5
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--list0, 总的不分区市省最新
local list0 = {}
local z0 = ssdb:zrrange("workroom_0_w_new", 0, limit)
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
			--list0[#list0+1] = w
			table.insert(list0, w)
		end
	end
end

--list1, 区最新
local list1 = {}
local z1 = ssdb:zrrange("workroom_1_w_new", 0, limit)
if z1 and z1[1] and z1[1] ~= "ok" then
	local wids = {}
	for i=1,#z1,2 do
		table.insert(wids, z1[i])
	end
	local w0 = ssdb:multi_hget("workroom_workrooms", unpack(wids))
	if w0 and w0[1] and w0[1] ~= "ok" then
		for i=1,#w0,2 do
			local w = cjson.decode(w0[i+1])
			w.stage = nil
			--list1[#list1+1] = w
			table.insert(list1, w)
		end
	end
end

--list2, 市最新
local list2 = {}
local z2 = ssdb:zrrange("workroom_2_w_new", 0, limit)
if z2 and z2[1] and z2[1] ~= "ok" then
	local wids = {}
	for i=1,#z2,2 do
		table.insert(wids, z2[i])
	end
	local w0 = ssdb:multi_hget("workroom_workrooms", unpack(wids))
	if w0 and w0[1] and w0[1] ~= "ok" then
		for i=1,#w0,2 do
			local w = cjson.decode(w0[i+1])
			w.stage = nil
			--list2[#list2+1] = w
			table.insert(list2, w)
		end
	end
end

--list3, 省最新
local list3 = {}
local z3 = ssdb:zrrange("workroom_3_w_new", 0, limit)
if z3 and z3[1] and z3[1] ~= "ok" then
	local wids = {}
	for i=1,#z3,2 do
		table.insert(wids, z3[i])
	end
	local w0 = ssdb:multi_hget("workroom_workrooms", unpack(wids))
	if w0 and w0[1] and w0[1] ~= "ok" then
		for i=1,#w0,2 do
			local w = cjson.decode(w0[i+1])
			w.stage = nil
			--list3[#list3+1] = w
			table.insert(list3, w)
		end
	end
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.list0 = list0
returnjson.list1 = list1
returnjson.list2 = list2
returnjson.list3 = list3
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)