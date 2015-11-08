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
local wq_id = args["wq_id"];
local create_source = args["create_source"];
local cause_content = args["cause_content"];
local is_delete = args["is_delete"];

local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
wrongQuestionBookModel:wq_edit(wq_id,create_source,cause_content,is_delete);
say("{\"success\":true,\"info\":\"保存成功\"}");
