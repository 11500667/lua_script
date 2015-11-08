--[[
@Author cuijinlong
@date 2015-4-24
--]]
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local student_id = args["student_id"];
local class_id = args["class_id"];
local topic_id = args["topic_id"];
local TopicModel = require "yxx.topic.model.TopicModel";
TopicModel:add_topic_student(student_id,class_id,topic_id);
ngx.say("{\"success\":true}")
