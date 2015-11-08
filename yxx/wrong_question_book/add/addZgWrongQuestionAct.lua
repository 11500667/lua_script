local say = ngx.say;
local cjson = require "cjson";
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local zy_id = tonumber(args["zy_id"]);
local student_id = args["student_id"];
local class_id = args["class_id"];
local subject_id = args["subject_id"];
local ssdb_info = {};
local zyModel = require "zy.model.zyModel";
local stringUtil = require "yxx.wrong_question_book.util.stringUtil";					--主要为了处理知识点Code用的。
local analyseDataService = require "study.analyse.services.AnalyseDataService";
local question_table = zyModel:get_zy_zg_question_ids(zy_id);
for i=1,#question_table do
    local question_id = question_table[i].question_id_char;								--试题ID
    ssdb_info["student_id"]= student_id;											--学生ID
    ssdb_info["class_id"] = class_id;												--班级ID
    ssdb_info["subject_id"] =subject_id;											--学科
    ssdb_info["create_source"] =1;										            --错题来源
    ssdb_info["create_time"] = ngx.localtime();										--错题时间
    ssdb_info["stu_answer"] = "";										            --学生答案
    ssdb_info["cause_content"] = 4;													--错题原因
    ssdb_info["priority_levels"] = 1;												--错题优先级
    ssdb_info["question_id"] = question_id;											--试题ID
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local questionBase = require "question.model.QuestionBase";
    local question_info = questionBase:getQuesDetailByIdChar(ssdb_info["question_id"]);
    local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info["knowledge_point_codes"]);
    ssdb_info["question_answer"] = question_info["question_answer"];  				--试题答案
    ssdb_info["question_type_id"] = question_info["question_type_id"];
    ssdb_info["question_type_name"] = question_info["question_type_name"];
    ssdb_info["nd_id"] = question_info["nd_id"];
    ssdb_info["nd_name"] = question_info["nd_name"];
    ssdb_info["nd_star"] = question_info["nd_star"];          						-- 难度星级
    ssdb_info["file_id"] = question_info["file_id"];          						-- 用于获取文件路径的guid
    ssdb_info["knowledge_point_ids"] = question_info["knowledge_point_ids"];		-- 知识点ID的字符串
    ssdb_info["knowledge_point_names"] = question_info["knowledge_point_names"];	-- 知识点ID的字符串
    ssdb_info["knowledge_point_codes"] = knowledge_point_codes;						-- 知识点CODE的字符串
    ssdb_info["zy_id"]= zy_id;
    ssdb_info["is_delete"] = 0;		                                                -- 表示我不会，默认是我不会
    local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
    local is_exsit = wrongQuestionBookModel:wq_is_exsit(ssdb_info["student_id"],ssdb_info["question_id"]);--判断此题之前是否做错过，如果错过那么本次就不加到错题本了
    if is_exsit[1] == "0" then
        wrongQuestionBookModel:zg_wq_save(ssdb_info);
        wrongQuestionBookModel:wq_rate(ssdb_info["class_id"],ssdb_info["question_id"],ssdb_info["subject_id"],question_info["knowledge_point_ids"],knowledge_point_codes,question_info["question_type_id"],question_info["question_type_name"],question_info["nd_id"],question_info["nd_name"],0);--该班级这道题的错题个数+1
    else
        wrongQuestionBookModel:wq_rate(ssdb_info["class_id"],ssdb_info["question_id"],ssdb_info["subject_id"],question_info["knowledge_point_ids"],knowledge_point_codes,question_info["question_type_id"],question_info["question_type_name"],question_info["nd_id"],question_info["nd_name"],0);--该班级这道题的对题个数+1
        wrongQuestionBookModel:more_once_wq(ssdb_info["student_id"],ssdb_info["question_id"],ssdb_info["stu_answer"]);
    end
    analyseDataService: insertAnalyseData(ssdb_info["subject_id"], ssdb_info["class_id"],student_id, ssdb_info["question_id"], 0);
    --ngx.say(cjson.encode(ssdb_info));
end
say("{\"success\":true,\"info\":\"保存成功\"}")