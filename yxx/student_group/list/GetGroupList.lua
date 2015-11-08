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
local teacher_id = args["teacher_id"];
local class_id = args["class_id"];
local subject_id = args["subject_id"];
if not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0  or not subject_id or string.len(subject_id) == 0  then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local groupModel = require "yxx.student_group.model.GroupModel"
groupModel:get_group_list(class_id,teacher_id,subject_id);
say("{\"success\":true,\"info\":\"保存成功\"}")
