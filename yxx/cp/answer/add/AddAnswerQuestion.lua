--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local cjson = require "cjson"
local answerModel = require "yxx.cp.answer.model.AnswerModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local stringUtil = require "yxx.wrong_question_book.util.stringUtil";
local questionBase = require "question.model.QuestionBase";
--  获取request的参数
local cp_id = parameterUtil:getStrParam("cp_id", "");
local question_id = parameterUtil:getStrParam("question_id", "");
local identity_id = parameterUtil:getStrParam("identity_id", "");
local cp_type_id = parameterUtil:getStrParam("cp_type_id", "");
local person_id = parameterUtil:getStrParam("person_id", "");
local class_id = parameterUtil:getStrParam("class_id", "");
local bus_id = parameterUtil:getStrParam("bus_id", "");
local answer = parameterUtil:getStrParam("answer", "");

if string.len(cp_id) == 0 then
    say("{\"success\":false,\"info\":\"cp_id参数错误！\"}")
    return
end
if string.len(question_id) == 0 then
    say("{\"success\":false,\"info\":\"question_id参数错误！\"}")
    return
end
if string.len(identity_id) == 0 then
    say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
if string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

if string.len(cp_type_id) == 0 then
    say("{\"success\":false,\"info\":\"cp_type_id参数错误！\"}")
    return
end
if string.len(class_id) == 0 then
    say("{\"success\":false,\"info\":\"class_id参数错误！\"}")
    return
end
if string.len(bus_id) == 0 then
    say("{\"success\":false,\"info\":\"bus_id参数错误！\"}")
    return
end
-- todo 通过试题ID获得试题库中试题详情 start
local question_info = questionBase:getQuesDetailByIdChar(question_id);
local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info["knowledge_point_codes"]);
-- todo 通过试题ID获得试题库中试题详情 end

-- todo 判断学生的作答是否正确 start
if string.len(answer) > 0 then
    local is_full_score = 0;
    if tostring(answer) == tostring(question_info["question_answer"]) then
        is_full_score = 1;
    end
    local table = {"cp_id",cp_id,"question_id",question_id,"identity_id",identity_id,
                   "person_id",person_id,"cp_type_id",cp_type_id,"class_id",class_id,
                   "bus_id",bus_id,"answer",answer,"difficulty_type",question_info["nd_id"],
                   "question_type",question_info["question_type_id"],"knowledge_point_codes",knowledge_point_codes,
                   "score",0,"is_full_score",is_full_score};
    answerModel:SetAnswerQuestion(table);
else
    local table = {"cp_id",cp_id,"question_id",question_id,"identity_id",identity_id,"person_id",person_id,"cp_type_id",cp_type_id};
    answerModel:DelAnswerQuestion(table);
end
-- todo 判断学生的作答是否正确 end



