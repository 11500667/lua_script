--[[
根据region_id和person_id查询名师
@Author feiliming
@Date   2014-12-31
]]

local say = ngx.say
local len = string.len
local gsub = string.gsub

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local person_id = ngx.var.arg_person_id
local region_id = ngx.var.arg_region_id
if not person_id or len(person_id) == 0
	or not region_id or len(region_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

person_id = gsub(person_id, "[\" ]", "")

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--没找到这个地区的工作室
local workroom_region = ssdb:hget("workroom_region", region_id)
if not workroom_region or len(workroom_region[1]) == 0 then
    say("{\"success\":false,\"info\":\"地区尚未工作室！\"}")
    return
end
--有但关闭
local wr = cjson.decode(workroom_region[1])
if wr.status ~= "1" then
	say("{\"success\":false,\"info\":\"工作室关闭了！\"}")
    return
end

--查工作室详情
local s_w = ssdb:hget("workroom_workrooms", wr.workroom_id)
local workroom = cjson.decode(s_w[1])

local tea_list = {}
--根据person_id找对应名师
local t_pids = Split(person_id, ",")
for i=1,#t_pids do
	local s_tids = ssdb:hget("workroom_person_teacher", t_pids[i])
	if s_tids and s_tids[1] and len(s_tids[1]) > 0 then
		local t_tids = Split(s_tids[1], ",")
		for j=1,#t_tids do
			local s_tea = ssdb:hget("workroom_teachers", t_tids[j])
			if s_tea and s_tea[1] and len(s_tea[1]) > 0 then
				--ngx.log(ngx.ERR, "=========="..s_tea[1])
				local t_tea = cjson.decode(s_tea[1])
				if tostring(t_tea.workroom_id) == tostring(workroom.workroom_id) then
					tea_list[#tea_list + 1] = t_tea
				end
			end
		end
	end
end

--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = person_id }
})
if res_person.status == 200 then
    personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end

--合并tea_list和personlist
for i=1,#tea_list do
	for j=1,#personlist do
		if tostring(tea_list[i].person_id) == tostring(personlist[j].person_id) then
			tea_list[i].person_name = personlist[j].person_name
			tea_list[i].school_id = personlist[j].bureau_id
			tea_list[i].school_name = personlist[j].org_name
			tea_list[i].stage_id = personlist[j].stage_id
			tea_list[i].stage_name = personlist[j].stage_name
			tea_list[i].subject_id = personlist[j].subject_id
			tea_list[i].subject_name = personlist[j].subject_name
			tea_list[i].workroom_name = workroom.name
			tea_list[i].region_id = region_id
			break
		end
	end
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.list = tea_list
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)