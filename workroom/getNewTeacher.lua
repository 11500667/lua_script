--[[
获取最新名师
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
local z0 = ssdb:zrrange("workroom_0_t_new", 0, limit)
if z0 and z0[1] and z0[1] ~= "ok" then
	local tids = {}
	for i=1,#z0,2 do
		table.insert(tids, z0[i])
	end
	local t0 = ssdb:multi_hget("workroom_teachers", unpack(tids))
	local pids = {}
	if t0 and t0[1] and t0[1] ~= "ok" then
		for i=1,#t0,2 do
			local t = cjson.decode(t0[i+1])
			table.insert(pids, t.person_id)
			list0[#list0+1] = t
		end
	end
	--获取person_id详情, 调用java接口
	local personlist
	local res_person = ngx.location.capture("/getTeaDetailInfo", {
		args = { person_id = table.concat(pids,",") }
	})
	if res_person.status == 200 then
	    personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
	    return
	end
	--合并list0和personlist
	for i=1,#list0 do
		for j=1,#personlist do
			if list0[i].person_id == tostring(personlist[j].person_id) then
				list0[i].person_name = personlist[j].person_name
				list0[i].school_id = personlist[j].bureau_id
				list0[i].school_name = personlist[j].org_name
				list0[i].stage_id = personlist[j].stage_id
				list0[i].stage_name = personlist[j].stage_name
				list0[i].subject_id = personlist[j].subject_id
				list0[i].subject_name = personlist[j].subject_name
				break
			end
		end
	end
end

--list1, 区最新
local list1 = {}
local z1 = ssdb:zrrange("workroom_1_t_new", 0, limit)
if z1 and z1[1] and z1[1] ~= "ok" then
	local tids = {}
	for i=1,#z1,2 do
		table.insert(tids, z1[i])
	end
	local t0 = ssdb:multi_hget("workroom_teachers", unpack(tids))
	local pids = {}
	if t0 and t0[1] and t0[1] ~= "ok" then
		for i=1,#t0,2 do
			local t = cjson.decode(t0[i+1])
			table.insert(pids, t.person_id)
			list1[#list1+1] = t
		end
	end
	--获取person_id详情, 调用java接口
	local personlist
	local res_person = ngx.location.capture("/getTeaDetailInfo", {
		args = { person_id = table.concat(pids,",") }
	})
	if res_person.status == 200 then
	    personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
	    return
	end
	--合并list0和personlist
	for i=1,#list1 do
		for j=1,#personlist do
			if list1[i].person_id == tostring(personlist[j].person_id) then
				list1[i].person_name = personlist[j].person_name
				list1[i].school_id = personlist[j].bureau_id
				list1[i].school_name = personlist[j].org_name
				list1[i].stage_id = personlist[j].stage_id
				list1[i].stage_name = personlist[j].stage_name
				list1[i].subject_id = personlist[j].subject_id
				list1[i].subject_name = personlist[j].subject_name
				break
			end
		end
	end
end

--list2, 市最新
local list2 = {}
local z2 = ssdb:zrrange("workroom_2_t_new", 0, limit)
if z2 and z2[1] and z2[1] ~= "ok" then
	local tids = {}
	for i=1,#z2,2 do
		table.insert(tids, z2[i])
	end
	local t0 = ssdb:multi_hget("workroom_teachers", unpack(tids))
	local pids = {}
	if t0 and t0[1] and t0[1] ~= "ok" then
		for i=1,#t0,2 do
			local t = cjson.decode(t0[i+1])
			table.insert(pids, t.person_id)
			list2[#list2+1] = t
		end
	end
	--获取person_id详情, 调用java接口
	local personlist
	local res_person = ngx.location.capture("/getTeaDetailInfo", {
		args = { person_id = table.concat(pids,",") }
	})
	if res_person.status == 200 then
	    personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
	    return
	end
	--合并list2和personlist
	for i=1,#list2 do
		for j=1,#personlist do
			if list2[i].person_id == tostring(personlist[j].person_id) then
				list2[i].person_name = personlist[j].person_name
				list2[i].school_id = personlist[j].bureau_id
				list2[i].school_name = personlist[j].org_name
				list2[i].stage_id = personlist[j].stage_id
				list2[i].stage_name = personlist[j].stage_name
				list2[i].subject_id = personlist[j].subject_id
				list2[i].subject_name = personlist[j].subject_name
				break
			end
		end
	end
end

--list3, 省最新
local list3 = {}
local z3 = ssdb:zrrange("workroom_3_t_new", 0, limit)
if z3 and z3[1] and z3[1] ~= "ok" then
	local tids = {}
	for i=1,#z3,2 do
		table.insert(tids, z3[i])
	end
	local t0 = ssdb:multi_hget("workroom_teachers", unpack(tids))
	local pids = {}
	if t0 and t0[1] and t0[1] ~= "ok" then
		for i=1,#t0,2 do
			local t = cjson.decode(t0[i+1])
			table.insert(pids, t.person_id)
			list3[#list3+1] = t
		end
	end
	--获取person_id详情, 调用java接口
	local personlist
	local res_person = ngx.location.capture("/getTeaDetailInfo", {
		args = { person_id = table.concat(pids,",") }
	})
	if res_person.status == 200 then
	    personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
	    return
	end
	--合并list3和personlist
	for i=1,#list3 do
		for j=1,#personlist do
			if list3[i].person_id == tostring(personlist[j].person_id) then
				list3[i].person_name = personlist[j].person_name
				list3[i].school_id = personlist[j].bureau_id
				list3[i].school_name = personlist[j].org_name
				list3[i].stage_id = personlist[j].stage_id
				list3[i].stage_name = personlist[j].stage_name
				list3[i].subject_id = personlist[j].subject_id
				list3[i].subject_name = personlist[j].subject_name
				break
			end
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