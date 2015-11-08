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
local student_id = 48--ngx.var.cookie_person_id;
local class_id = tonumber(args["class_id"]);
local question_id = tonumber(args["question_id"]);
local subject_id = tonumber(args["subject_id"]);
if not class_id or string.len(class_id) == 0 or not question_id or string.len(question_id) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
local is_exsit = wrongQuestionBookModel:wq_is_exsit(student_id,question_id);--判断此题之前是否做过，如果错过那么本次就不加到错题本了
if is_exsit[1] == "0" then
	wrongQuestionBookModel:wq_rate(class_id,question_id,subject_id,1);--该班级这道题的对题个数+1
end
say("{\"success\":true,\"info\":\"保存成功\"}")