--[[
@Author chuzheng
@date 2014-12-18
--]]
local say = ngx.say

--引用模块
local ssdblib = require "resty.ssdb"
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local table = {};
local teacher_id = args["teacher_id"];
local class_id = args["class_id"];
local group_name = args["group_name"];
local subject_id = args["subject_id"];
if not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0 or not group_name or string.len(group_name) == 0 or not subject_id or string.len(subject_id) == 0  then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
table.teacher_id = tonumber(teacher_id);
table.class_id = tonumber(class_id);
table.group_name = group_name;
table.subject_id = tonumber(subject_id);
local groupModel = require "yxx.student_group.model.GroupModel"
groupModel:create_group(table);
say("{\"success\":true,\"info\":\"保存成功\"}")
