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

if args["question_id"] == nil or args["question_id"]==""  then
	ngx.print("{\"success\":false,\"info\":\"必要的参数question_id不能为空！\"}");
	return;
end
local question_id = tonumber(args["question_id"]);
local class_ids = tostring(args["class_ids"]);
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
--学生获得我的错题列表
local return_json = wrongQuestionBookModel:wq_all_stu_list(question_id,class_ids);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_json);
say(responseJson);
	