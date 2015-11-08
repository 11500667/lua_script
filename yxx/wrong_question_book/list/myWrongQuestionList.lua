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
if args["subject_id"] == nil or args["subject_id"]=="" or args["create_source"] == nil or args["create_source"]=="" or args["cause_content"] == nil or args["cause_content"]=="" then
	ngx.print("{\"success\":false,\"info\":\"subject_id,create_source,cause_content不能为空！\"}");
	return;
end
local student_id = ngx.var.cookie_person_id;
local knowledge_point_code = tonumber(args["knowledge_point_code"]);
local is_include_know = tonumber(args["is_include_know"]);
local subject_id = tonumber(args["subject_id"]);
local create_source = tonumber(args["create_source"]);
local cause_content = tonumber(args["cause_content"]);
local sort_type = tonumber(args["sort_type"]);
local sort_num =tonumber(args["sort_num"]);
local page_size = tonumber(args["page_size"]);
local page_number = tonumber(args["page_number"]);
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
--学生获得我的错题列表
local return_list = wrongQuestionBookModel:person_wq_list(student_id,subject_id,create_source,cause_content,knowledge_point_code,is_include_know,sort_type,sort_num,page_size,page_number);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_list);
say(responseJson);