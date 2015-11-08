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

local ssdb_info = {};
--[[ ssdb_info["student_id"]= ;					--学生ID
ssdb_info["class_id"] = 2200;											--班级ID
ssdb_info["subject_id"] = tonumber(args["subject_id"]);					--学科
ssdb_info["knowledge_point"] = tonumber(args["knowledge_point"]);		--知识点
ssdb_info["create_source"] = tonumber(args["create_source"]);			--错题来源
ssdb_info["create_time"] = ngx.localtime();								--错题时间
ssdb_info["stu_answer"] = args["stu_answer"];							--学生答案
ssdb_info["cause_content"] = tonumber(args["cause_content"]);			--错题原因
ssdb_info["quality_goods"] = tonumber(args["quality_goods"]);			--是否精品
ssdb_info["priority_levels"] = tonumber(args["priority_levels"]);		--错题优先级
ssdb_info["question_id"] = ;				--试题ID ]]
ssdb_info["student_id"]= 25;							--学生ID
ssdb_info["class_id"] = 0941;							--班级ID
ssdb_info["subject_id"] =6;								--学科
ssdb_info["knowledge_point"] = 402;						--知识点
ssdb_info["create_source"] =1;							--错题来源
ssdb_info["create_time"] = ngx.localtime();				--错题时间
ssdb_info["stu_answer"] = "A";							--学生答案
ssdb_info["cause_content"] = 1;							--错题原因
ssdb_info["quality_goods"] = 2;							--是否精品
ssdb_info["priority_levels"] = 3;						--错题优先级
ssdb_info["question_id"] = 1000000009;				--试题ID

local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
wrongQuestionBookModel:wq_delete(student_id,question_id,wq_id);
say("{\"success\":true,\"info\":\"成功移除错题\"}")