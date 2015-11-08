--[[
@Author cuijinlong
@date 2015-4-24
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
local subject_id = args["subject_id"];
if not subject_id or string.len(subject_id) == 0 then
    say("{\"success\":false,\"info\":\"subject_id:不能为空！\"}")
    return
end
local topicModel = require "yxx.topic.model.TopicModel";
local topicListJson = topicModel:type_list(subject_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(topicListJson);
say(responseJson);