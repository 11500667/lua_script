--[[
前台接口，获得某个级别(0,1,2,3)下的最热名师，不够的拿访问次数最多的补齐
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
local personids = {}
local z0 = ssdb:zrange("workroom_"..level.."_t_hot", 0, limit)
if z0 and z0[1] and z0[1] ~= "ok" then
	local tids = {}
	for i=1,#z0,2 do
		table.insert(tids, z0[i])
	end
	local t0 = ssdb:multi_hget("workroom_teachers", unpack(tids))
	if t0 and t0[1] and t0[1] ~= "ok" then
		for i=1,#t0,2 do
			local t = cjson.decode(t0[i+1])
			--t.description = nil
			--t.avatar_url = nil
			table.insert(list0, t)
			table.insert(personids, t.person_id)
		end
	end
end

--判断补齐,取最新里面的
limit = tonumber(limit)
if #list0 < limit then
	local b0 = ssdb:zrrange("workroom_"..level.."_t_new", 0, limit * 2)
	if b0 and b0[1] and b0[1] ~= "ok" then
		local tids = {}
		for i=1,#b0,2 do
			table.insert(tids, b0[i])
		end
		local t0 = ssdb:multi_hget("workroom_teachers", unpack(tids))
		if t0 and t0[1] and t0[1] ~= "ok" then
			for i=1,#t0,2 do
				if #list0 >= limit then
					break
				end
				local t = cjson.decode(t0[i+1])
				local flag = false
				for j=1,#list0 do
					if tostring(list0[j].teacher_id) == tostring(t.teacher_id) then
						flag = true
						break
					end
				end
				if not flag then
					table.insert(list0, t)
					table.insert(personids, t.person_id)
				end
			end
		end
	end
end

--获取person_id详情, 调用java接口
local personlist = {}
if #personids > 0 then
	local res_person = ngx.location.capture("/getTeaDetailInfo", {
		args = { person_id = table.concat(personids,",") }
	})
	if res_person.status == 200 then
	    personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
	    return
	end
end
--合并list和personlist
for i=1,#list0 do
	for j=1,#personlist do
		if list0[i].person_id == tostring(personlist[j].person_id) then
			list0[i].person_name = personlist[j].person_name
			list0[i].school_id = personlist[j].bureau_id
			list0[i].school_name = personlist[j].org_name
			--list0[i].stage_id = personlist[j].stage_id
			--list0[i].stage_name = personlist[j].stage_name
			--list0[i].subject_id = personlist[j].subject_id
			--list0[i].subject_name = personlist[j].subject_name
			break
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