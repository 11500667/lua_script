--[[
后台接口, 按级别(0,1,2,3)查询工作室, 设置最热时调用
@Author feiliming
@Date   2015-1-12
]]
local say = ngx.say
local len = string.len

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local level = ngx.var.arg_level
if not level or len(level) == 0 then
	level = 0
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据level查
local limit = 10000
local list0 = {}
local z0 = ssdb:zrange("workroom_"..level.."_w_new", 0, limit)
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
			w.description = nil
			table.insert(list0, w)
		end
	end
end
--根据level查
local wids = {}
local z1 = ssdb:zrange("workroom_"..level.."_w_hot", 0, 100)
if z1 and z1[1] and z1[1] ~= "ok" then
	for i=1,#z1,2 do
		table.insert(wids, z1[i])
	end
end
for i=1,#list0 do
	local flag = 0
	for j=1,#wids do
		if list0[i].workroom_id == tostring(wids[j]) then
			flag = 1
			break
		end
	end
	list0[i].selected = flag
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.list = list0
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)