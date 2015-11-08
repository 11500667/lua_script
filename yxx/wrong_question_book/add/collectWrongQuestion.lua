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
local student_id = ngx.var.cookie_person_id;
local question_id = args["question_id"];
local ssdb_info = {};
ssdb_info["student_id"]= student_id;											--学生ID
ssdb_info["class_id"] = ngx.var.cookie_class_id;								--班级ID
ssdb_info["subject_id"] = args["subject_id"];									--学科
ssdb_info["create_source"] =4;													--错题来源
ssdb_info["create_time"] = ngx.localtime();										--错题时间
ssdb_info["stu_answer"] = "错题收藏";											--学生答案
ssdb_info["cause_content"] = 4;													--错题原因
ssdb_info["priority_levels"] = 1;												--错题优先级
ssdb_info["question_id"] = question_id;											--246068;--试题ID
local stringUtil = require "yxx.wrong_question_book.util.stringUtil";
local questionBase = require "question.model.QuestionBase";
local question_info = questionBase:getQuesDetailByIdChar(ssdb_info["question_id"]);
local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info["knowledge_point_codes"]);
ssdb_info["question_answer"] = question_info["question_answer"];  				--试题答案
ssdb_info["question_type_name"] = question_info["question_type_name"];			--试题类型名称   
ssdb_info["nd_name"]  = question_info["nd_name"];         						-- 难度名称
ssdb_info["nd_star"] = question_info["nd_star"];          						-- 难度星级
ssdb_info["file_id"] = question_info["file_id"];          						-- 用于获取文件路径的guid
ssdb_info["knowledge_point_ids"] = question_info["knowledge_point_ids"];		-- 知识点ID的字符串
ssdb_info["knowledge_point_codes"] = knowledge_point_codes;						-- 知识点CODE的字符串
ssdb_info["knowledge_point_names"] = question_info["knowledge_point_names"];	-- 知识点ID的字符串
ssdb_info["is_delete"] = 0;														-- 表示我不会
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
local is_exsit = wrongQuestionBookModel:wq_is_exsit(student_id,question_id);--判断此题之前是否做错过，如果错过那么本次就不加到错题本了。
if is_exsit[1] == "0" then
	wrongQuestionBookModel:wq_save(ssdb_info);
	say("{\"success\":true,\"info\":\"收藏成功！\"}");
else
	say("{\"success\":false,\"info\":\"您的错题本已存在此题！\"}");
end