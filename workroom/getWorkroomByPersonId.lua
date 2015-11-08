--[[
根据person_id查所属工作室
@Author  feiliming
@Date    2014-12-2
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local person_id = ngx.var.arg_person_id
if not person_id or string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local t_teacherids, err = ssdb:hget("workroom_person_teacher", person_id)
local workroom_ids = ""
local workroom_list = {}
if string.len(t_teacherids[1]) ~= 0 then
	local a_teacherids = Split(t_teacherids[1], ",")
	for i=1,#a_teacherids do
		local t_teacher, err = ssdb:hget("workroom_teachers", a_teacherids[i])
		local teacher = cjson.decode(t_teacher[1])
		workroom_ids = workroom_ids..teacher.workroom_id..","

		local t_workroom = ssdb:hget("workroom_workrooms", teacher.workroom_id)
		local workroom = cjson.decode(t_workroom[1])
		local workroom2 = {}
		workroom2.workroom_id = workroom.workroom_id
		workroom2.name = workroom.name
		workroom_list[#workroom_list+1] = workroom2
	end
end
if string.len(workroom_ids) > 0 then
	workroom_ids = string.sub(workroom_ids, 1, string.len(workroom_ids)-1)
end

local returnjson = {}
returnjson.success = true
returnjson.workroom_ids = workroom_ids
returnjson.workroom_list = workroom_list

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)