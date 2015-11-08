--[[
@Author cuijinlong
@date 2015-6-10
--]]
local say = ngx.say
local cjson = require "cjson"
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
local record_count = args["record_count"];
if not student_id or string.len(student_id) == 0 or not record_count or string.len(record_count) == 0 then
    say("{\"success\":false,\"info\":\"student_id、record_count:不能为空！\"}")
    return
end
local TopicModel = require "yxx.topic.model.TopicModel";
local topicListJson = TopicModel:topic_student_list(student_id,record_count);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(topicListJson);
say(responseJson);
