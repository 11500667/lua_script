--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["question_ids"] == nil or args["question_ids"]=="" then
	ngx.print("{\"success\":false,\"info\":\"question_ids能不为空\"}");
	return;
end
local question_ids = args["question_ids"];
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
local return_json = wrongQuestionBookModel:recommend_question_by_ids(question_ids);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_json);
say(responseJson);
	