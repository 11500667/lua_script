--
-- 学生点评 -> 获取教师在指定班级下创建的话题列表
-- 请求方式：GET
-- 作者: shenjian
-- 日期: 2015/5/5 14:50
--

-- 1.获取参数
local request_method = ngx.var.request_method;
local args;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["teacher_id"] == nil or args["teacher_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数teacher_id不能为空！\"}");
    return;
elseif args["class_id"] == nil or args["class_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数class_id不能为空！\"}");
    return;
end

local teacherId  = tonumber(args["teacher_id"]);
local classId    = tonumber(args["class_id"]);

local commentService = require "study.comment.services.CommentService";
local resultJsonObj  = commentService: getTopicListNoPage(teacherId, classId);

local cjson = require "cjson";
ngx.print(cjson.encode(resultJsonObj));