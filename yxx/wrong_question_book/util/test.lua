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
local question_id = args["question_id"];
local class_id = args["class_id"];
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
local return_str = wrongQuestionBookModel:wq_all_stu_list(question_id,class_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_str);
say(responseJson);