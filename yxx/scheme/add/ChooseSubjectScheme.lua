--[[
@Author chuzheng
@date 2014-12-18
--]]
local say = ngx.say
local termModel = require "base.term.model.TermModel";
--引用模块
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local teacher_id = args["teacher_id"];
local subject_id = args["subject_id"];
local version_id = args["version_id"];
local version_name = args["version_name"];
local root_structure_id = args["root_structure_id"];
if  not subject_id or string.len(subject_id) == 0
            or not version_id or string.len(version_id) == 0
                or not version_name or string.len(version_name) == 0
                    or not teacher_id or string.len(teacher_id) == 0
                        or not root_structure_id or string.len(root_structure_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local table = {};
table.teacher_id = teacher_id;
table.subject_id = subject_id;
table.xq_id = termModel:get_current_term();
table.version_id = version_id;
table.version_name = version_name;
table.root_structure_id = root_structure_id;
local schemeModel = require "yxx.scheme.model.SchemeModel";
schemeModel:teach_choose_scheme(table);
say("{\"success\":true,\"info\":\"保存成功\"}")
