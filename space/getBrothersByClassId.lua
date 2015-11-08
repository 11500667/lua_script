--[[
前台接口Lua，根据班级id查询兄弟班级
@Author feiliming
@Date   2015-7-11
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

local classService = require "base.class.services.ClassService";
local result  = classService:getBrotherClassByClassId(class_id);
if not result or not result.success then
	say("{\"success\":false,\"info\":\"调用基础接口出错！\"}")
    return
end

local classIds = {}
local classlist = result.class_list
for i=1,#classlist do
	table.insert(classIds, classlist[i].class_id)
end

--调用空间接口取基本信息
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getOrgBaseInfo("105", unpack(classIds))
for i=1,#classlist do
    for _, v in ipairs(rt) do
        if tostring(classlist[i].class_id) == tostring(v.orgId) then
            classlist[i].org_logo_fileid = v and v.org_logo_fileid or ""
            break
        end
    end
end

local rr = {}
rr.success = true
rr.list = classlist
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

