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
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
if not args["teacher_id"] and not args["class_id"] then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local teacher_id = "";
if class_id then
    teacher_id = personInfoModel:getTeachByClassSubject(class_id,subject_id);
else
    teacher_id = args["teacher_id"];
end
local row = schemeModel:get_scheme_by_teach_subject(teacher_id,termModel:get_current_term(),subject_id);
if row and #row>0 then
    say("{\"success\":true,\"version_id\":\"".. row[1].version_id.."\",\""..row[1].version_name.."}");
else
    say("{\"success\":false}");
end

