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
if args["subject_id"] == nil or args["subject_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"必要的参数subject_id不能为空！\"}");
	return;
end
local subject_id = args["subject_id"];
local topic_type_id = args["topic_type_id"];
local topic_name = args["topic_name"];
local page_size = tonumber(args["page_size"]);
local page_number = tonumber(args["page_number"]);
local android_ios = args["android_ios"];
local topicModel = require "yxx.topic.model.TopicModel";
--学生获得我的错题列表
local return_json = topicModel:topic_list(subject_id,topic_name,topic_type_id,android_ios,page_size,page_number);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_json);
say(responseJson);
	