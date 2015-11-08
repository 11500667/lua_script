--[[
根据名师id查询名师详细
@Author   feiliming
@Date     2014-12-4
--]]

local say = ngx.say

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local teacher_id = ngx.var.arg_teacher_id
local person_id = ngx.var.arg_person_id
if not teacher_id or string.len(teacher_id) == 0 then
	say("{\"success:\":false,\"info\":\"参数错误！\"}")
	return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--查teacher_id
local res, err = ssdb:hget("workroom_teachers", teacher_id)
if not res or string.len(res[1]) == 0 then
	say("{\"success:\":false,\"info\":\"查无此名师！\"}")
end

local teacher = cjson.decode(res[1])
local person
local res_person, err = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = teacher.person_id }
})
if res_person.status == 200 then
    person = cjson.decode(res_person.body)[1]
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end

local wr, err = ssdb:hget("workroom_workrooms", teacher.workroom_id)
if not wr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local workroom = cjson.decode(wr[1])

--return
local returnjson = {}
returnjson.success = true
returnjson.teacher_id = teacher_id
returnjson.workroom_id = teacher.workroom_id
returnjson.workroom_name = workroom.name
returnjson.workroom_logo_url = workroom.logo_url
returnjson.person_id = teacher.person_id
returnjson.person_name = person.person_name
returnjson.avatar_url = teacher.avatar_url
returnjson.description = teacher.description
returnjson.level = teacher.level
returnjson.stage_id = person.stage_id
returnjson.stage_name = person.stage_name
returnjson.subject_id = person.subject_id
returnjson.subject_name = person.subject_name
returnjson.school_id = person.bureau_id
returnjson.school_name = person.org_name

if person_id and string.len(person_id) ~= 0 then
    --是否名师, 名师id
    local t_teacherids, err = ssdb:hget("workroom_person_teacher", person_id)
    if string.len(t_teacherids[1]) ~= 0 then
        returnjson.isteacher = "1"
        --是否当前工作室
        local a_teacherids = Split(t_teacherids[1], ",")
        for i=1,#a_teacherids do
            local t_teacher, err = ssdb:hget("workroom_teachers", a_teacherids[i])
            local teacher = cjson.decode(t_teacher[1])
            if teacher.workroom_id == workroom.workroom_id then
                returnjson.teacher_id = teacher.teacher_id
                returnjson.iscur = "1"
                break
            end
        end
        --如果不是当前工作室的,则teacher_id截取第一个
        if not returnjson.iscur then
            returnjson.teacher_id = a_teacherids[1]
        end
    end
end

if not returnjson.isteacher then
    returnjson.isteacher = "0"
end
if not returnjson.iscur then
    returnjson.iscur = "0"
end
if not returnjson.teacher_id then
    returnjson.teacher_id = "0"
end

--访问次数+1
local t_scan_count = ssdb:zget("workroom_"..workroom.level.."_teacher_sorted_by_scan_count", teacher_id)
if t_scan_count and string.len(t_scan_count[1]) > 0 then
    ssdb:zset("workroom_"..workroom.level.."_teacher_sorted_by_scan_count", teacher_id, tonumber(t_scan_count[1]) + 1)
else
    ssdb:zset("workroom_"..workroom.level.."_teacher_sorted_by_scan_count", teacher_id, 1)
end
--总次数
local t_scan_count1 = ssdb:zget("workroom_0_teacher_sorted_by_scan_count", teacher_id)
if t_scan_count1 and string.len(t_scan_count1[1]) > 0 then
    ssdb:zset("workroom_0_teacher_sorted_by_scan_count", teacher_id, tonumber(t_scan_count1[1]) + 1)
else
    ssdb:zset("workroom_0_teacher_sorted_by_scan_count", teacher_id, 1)
end

say(cjson.encode(returnjson))
ssdb:set_keepalive(0,v_pool_size)
