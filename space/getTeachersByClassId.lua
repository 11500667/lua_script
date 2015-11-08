--[[
前台接口Lua，根据班级id查询班级下的任课教师
@Author feiliming
@Date   2015-7-7
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"

--get args
local class_id = ngx.var.arg_class_id

if not class_id or len(class_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

local personService = require "base.person.services.PersonService";
local result  = personService:getTeacherByClass(class_id);
if not result or not result.success then
	say("{\"success\":false,\"info\":\"调用基础接口出错！\"}")
    return
end

local personIds = {}
local teacherlist = result.teacher_list
for i=1,#teacherlist do
	table.insert(personIds, teacherlist[i].person_id)
end

--调用空间接口取基本信息
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfo("5", unpack(personIds))
for i=1,#teacherlist do
    for _, v in ipairs(rt) do
        if tostring(teacherlist[i].person_id) == tostring(v.personId) then
            teacherlist[i].avatar_fileid = v and v.avatar_fileid or ""
            --teacherlist[i].description = v and v.person_description or ""
            break
        end
    end
end

local rr = {}
rr.success = true
rr.list = teacherlist
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

