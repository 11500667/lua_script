--[[
@Author cjl
@date 2015-7-15
--]]
local say = ngx.say
--引用模块
local termModel = require "base.term.model.TermModel";
local personInfoModel = require "base.person.model.PersonInfoModel";
local schemeModel = require "yxx.scheme.model.SchemeModel";
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local class_id = args["class_id"];
local subject_id = args["subject_id"];
if not subject_id or string.len(subject_id) == 0 then
    say("{\"success\":false,\"info\":\"学科不能为空！\"}");
    return
end
if not class_id or string.len(class_id) == 0 then
    say("{\"success\":false,\"info\":\"class_id不能为空！\"}");
    return
end
local teacher_id = personInfoModel:getTeachByClassSubject(class_id,subject_id);
local row = schemeModel:get_scheme_by_teach_subject(teacher_id,termModel:get_current_term(),subject_id);
if row and row[1] then
    say("{\"success\":true,\"version_id\":\"".. row[1].version_id.."\",\"version_name\":\""..row[1].version_name.."\",\"root_structure_id\":\""..row[1].root_structure_id.."\"}");
else
    say("{\"success\":false}");
end

