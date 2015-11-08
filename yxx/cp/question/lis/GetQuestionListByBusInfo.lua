--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local cjson = require "cjson"
local questionModel = require "yxx.cp.question.model.QuestionModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
--  获取request的参数
local paper_id       = parameterUtil:getStrParam("paper_id","");
if string.len(bus_id)==0 then
    say("{\"success\":false,\"info\":\"bus_id参数错误！\"}")
    return
end
local question_info = questionModel:getQuestionList(paper_id);

--学生获得我的错题列表
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(question_info);
say(responseJson);