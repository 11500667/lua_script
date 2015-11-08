--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local cjson = require "cjson"
local questionModel = require "yxx.cp.question.model.QuestionModel";
local answerModel = require "yxx.cp.answer.model.AnswerModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local SSDBUtil = require "yxx.tool.SSDBUtil";
--  获取request的参数
local paper_id = parameterUtil:getStrParam("paper_id", "");
local cp_id = parameterUtil:getStrParam("cp_id", "");
local identity_id = parameterUtil:getStrParam("identity_id", "");
local person_id = parameterUtil:getStrParam("person_id", "");
if string.len(paper_id) == 0 then
    say("{\"success\":false,\"info\":\"paper_id参数错误！\"}")
    return
end
if string.len(cp_id) == 0 then
    say("{\"success\":false,\"info\":\"cp_id参数错误！\"}")
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
-- todo 通过试卷ID获得试卷中的试题 start
local question_info = questionModel:getQuestionList(paper_id);
local kg_tab = question_info.kg;
if question_info and kg_tab then
    for i=1,#kg_tab do
        local answer_question_tab = SSDBUtil:multi_hget_hash("yxx_cp_answer_question_"..cp_id.."_"..kg_tab[i].question_id_char.."_"..identity_id.."_"..person_id,"question_id","answer","is_full_score");
        if answer_question_tab[1] ~= "ok" then
            kg_tab[i].answer = answer_question_tab.answer;
        else
            kg_tab[i].answer = "";
        end
    end
end
-- todo 查询到学生对试题的作答情况 end
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(question_info);
say(responseJson);
SSDBUtil:keepAlive();