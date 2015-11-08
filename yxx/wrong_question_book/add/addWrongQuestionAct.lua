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
ssdb_info["create_source"] = tonumber(args["create_source"]);			--错题来源
ssdb_info["create_time"] = ngx.localtime();								--错题时间
ssdb_info["stu_answer"] = args["stu_answer"];							--学生答案
ssdb_info["cause_content"] = tonumber(args["cause_content"]);			--错题原因
ssdb_info["priority_levels"] = tonumber(args["priority_levels"]);		--错题优先级
ssdb_info["question_id"] = tonumber(args["question_id"]);				--试题ID ]]
local student_id = args["student_id"];
local class_id = args["class_id"];
local subject_id = args["subject_id"];
local zy_id = args["zy_id"];
local create_source = args["create_source"];
if not student_id or string.len(student_id) == 0 or not class_id or string.len(class_id) == 0 or not subject_id or string.len(subject_id) == 0 or not zy_id or string.len(zy_id) == 0 or not create_source or string.len(create_source) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
local analyseDataService = require "study.analyse.services.AnalyseDataService";
local stringUtil = require "yxx.wrong_question_book.util.stringUtil";					--主要为了处理知识点Code用的。
local zyModel = require "zy.model.zyModel";												--作业提供的函数  --508 3班学生3  507 3班学生2   786   786
local answer_question_array = zyModel:get_zy_answer_question_info(student_id,zy_id);	--获得本次作业所有的错题ID
local wrong_question_infos = answer_question_array["wrong_question_infos"]; 			--"格式：2323_A,2234_B,2356_C   错题id_学生答案"
local right_question_ids = answer_question_array["right_question_ids"];					--本次作业做对的题的ID
--ngx.log(ngx.ERR,"#####wrong_question_infos:"..wrong_question_infos.."|right_question_ids:"..right_question_ids)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--错题信息录入错题本
if string.len(wrong_question_infos) > 0 then
    local wrong_question_infos_array = Split(wrong_question_infos,",");					--格式：{"2323_A","2323_A"}
    for i=1,#wrong_question_infos_array do
        local wrong_question_infos = wrong_question_infos_array[i]						--本次作业所有的错题
        local wrong_question_id_answer = Split(wrong_question_infos,"_");				--格式：{2323,"A"}
        local question_id = wrong_question_id_answer[1];								--试题ID
        local student_answer = wrong_question_id_answer[2];								--学生答案
        ssdb_info["student_id"]= student_id;											--学生ID
        ssdb_info["class_id"] = class_id;												--班级ID
        ssdb_info["subject_id"] =subject_id;											--学科
        ssdb_info["create_source"] =create_source;										--错题来源
        ssdb_info["create_time"] = ngx.localtime();										--错题时间
        ssdb_info["stu_answer"] = student_answer;										--学生答案
        ssdb_info["cause_content"] = 4;													--错题原因
        ssdb_info["priority_levels"] = 1;												--错题优先级
        ssdb_info["question_id"] = question_id;											--246068;--试题ID
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
        ssdb_info["is_delete"] = 0;														-- 表示我不会，默认是我不会
        local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
        local is_exsit = wrongQuestionBookModel:wq_is_exsit(ssdb_info["student_id"],ssdb_info["question_id"]);--判断此题之前是否做错过，如果错过那么本次就不加到错题本了
        if is_exsit[1] == "0" then
            wrongQuestionBookModel:wq_save(ssdb_info);
            wrongQuestionBookModel:wq_rate(ssdb_info["class_id"],ssdb_info["question_id"],ssdb_info["subject_id"],question_info["knowledge_point_ids"],knowledge_point_codes,question_info["question_type_id"],question_info["question_type_name"],question_info["nd_id"],question_info["nd_name"],0);--该班级这道题的错题个数+1
        else
            wrongQuestionBookModel:wq_rate(ssdb_info["class_id"],ssdb_info["question_id"],ssdb_info["subject_id"],question_info["knowledge_point_ids"],knowledge_point_codes,question_info["question_type_id"],question_info["question_type_name"],question_info["nd_id"],question_info["nd_name"],0);--该班级这道题的对题个数+1
            wrongQuestionBookModel:more_once_wq(ssdb_info["student_id"],ssdb_info["question_id"],ssdb_info["stu_answer"]);
        end
        analyseDataService: insertAnalyseData(ssdb_info["subject_id"], ssdb_info["class_id"],student_id, ssdb_info["question_id"], 0);
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--正确答题信息录入班级错题率表
if string.len(right_question_ids) > 0 then
    local right_question_id_array = Split(right_question_ids,",");
    for i=1,#right_question_id_array do
        local question_id = right_question_id_array[i];
        local questionBase = require "question.model.QuestionBase";
        local question_info = questionBase:getQuesDetailByIdChar(question_id);
        local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info["knowledge_point_codes"]);
        if not class_id or string.len(class_id) == 0 or not question_id or string.len(question_id) == 0 then
            say("{\"success\":false,\"info\":\"参数错误！\"}")
            return
        end
        local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
        local is_exsit = wrongQuestionBookModel:wq_is_exsit(student_id,question_id);--判断此题之前是否做过，如果错过那么本次就不加到错题本了
        if is_exsit[1] == "0" then
            wrongQuestionBookModel:wq_rate(class_id,question_id,subject_id,question_info["knowledge_point_ids"],knowledge_point_codes,question_info["question_type_id"],question_info["question_type_name"],question_info["nd_id"],question_info["nd_name"],1);--该班级这道题的对题个数+1
        end
        analyseDataService: insertAnalyseData(subject_id, class_id, student_id, question_id, 0);
    end
end
say("{\"success\":true,\"info\":\"保存成功\"}")