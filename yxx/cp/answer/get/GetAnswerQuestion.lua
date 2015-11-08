--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local answerModel = require "yxx.cp.answer.model.AnswerModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
--  获取request的参数
local cp_id = parameterUtil:getStrParam("cp_id", "");
local question_id = parameterUtil:getStrParam("question_id", "");
local identity_id = parameterUtil:getStrParam("identity_id", "");
local person_id = parameterUtil:getStrParam("person_id", "");

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
answerModel:GetAnswerQuestion(cp_id,question_id,identity_id,person_id);


