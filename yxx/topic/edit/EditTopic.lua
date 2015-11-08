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

local table = {};
table["topic_id"]  = args["topic_id"];--专题ID
table["topic_name"]  = args["topic_name"];--专题名称
table["stage_id"] = tonumber(args["stage_id"]);--学段
table["subject_id"] = tonumber(args["subject_id"]);--学科
table["type_id"]  = args["type_id"];--类型
if args["swf_url"] and args["swf_url_ext"] then
    table["swf_url"] = args["swf_url"].."."..args["swf_url_ext"];
end
table["swf_version"] = args["swf_version"];
if args["ios_url"] and args["ios_url_ext"] then
    table["ios_url"] = args["ios_url"].."."..args["ios_url_ext"];
end
table["ios_version"] = args["ios_version"];
if args["android_url"] and args["android_url_ext"] then
    table["android_url"] = args["android_url"].."."..args["android_url_ext"];
end
table["android_version"] = args["android_version"];
if args["thumb_url"] and args["thumb_url_ext"] then
    table["thumb_url"] = args["thumb_url"].."."..args["thumb_url_ext"];
end
local topicModel = require "yxx.topic.model.TopicModel";
topicModel:edit_topic(table)
ngx.say("{\"success\":true,\"info\":\"编辑成功\"}")