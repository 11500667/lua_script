--
-- 学生点评 -- 保存话题的请求接口
-- 请求方式：POST
-- User: shenjian
-- Date: 2015/5/5
-- Time: 14：30
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

local cjson = require "cjson";
ngx.log(ngx.ERR, "===> 保存话题的参数： [[[", cjson.encode(args), "]]]");


if args["teacher_id"] == nil or args["teacher_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数teacher_id不能为空！\"}");
    return;
elseif args["topic_name"] == nil or args["topic_name"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数topic_name不能为空！\"}");
    return;
end

local teacherId  = tonumber(args["teacher_id"]);
local topicName  = args["topic_name"];

local commentService = require "study.comment.services.CommentService";
local resultJsonObj  = commentService: createTopic(topicName, teacherId);


ngx.print(cjson.encode(resultJsonObj));