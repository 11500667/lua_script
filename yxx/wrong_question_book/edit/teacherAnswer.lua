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
if args["knowledge_point_code"] == nil or args["knowledge_point_code"]=="" or args["nd_id"] == nil or args["nd_id"]==""then
	ngx.print("{\"success\":false,\"info\":\"knowledge_point_code,nd_id不能为空\"}");
	return;
end

local knowledge_point_code = tostring(args["knowledge_point_code"]);
local nd_id = tonumber(args["nd_id"]);
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
local return_list = wrongQuestionBookModel:recommend_question(knowledge_point_code,nd_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_list);

say(responseJson);
