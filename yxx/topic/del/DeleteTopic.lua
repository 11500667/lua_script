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

local topic_id  = args["topic_id"];--专题ID
local topicModel = require "yxx.topic.model.TopicModel";
topicModel:del_topic(topic_id)
ngx.say("{\"success\":true,\"info\":\"删除成功\"}")