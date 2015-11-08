--[[
@Author chuzheng
@date 2014-12-18
@测试数据
功能：创建预习
--]]
local say = ngx.say;
local YxModel = require "yxx.preparation.student.model.YxModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local yx_id = parameterUtil:getStrParam("yx_id",'');--预习ID
local person_id = parameterUtil:getStrParam("person_id",'');--预习ID
local identity_id = parameterUtil:getStrParam("identity_id",'');--预习ID
if string.len(yx_id) == 0 then
    say("{\"success\":false,\"info\":\"yx_id不能为空!\"}");
    return;
end
if string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"person_id不能为空!\"}");
    return;
end
if string.len(identity_id) == 0 then
    say("{\"success\":false,\"info\":\"identity_id不能为空!\"}");
    return;
end
local sucess = YxModel:yxSubmit(yx_id,person_id,identity_id);
if sucess then
    say("{\"success\":true,\"info\":\"提交预习成功！\"}");
else
    say("{\"success\":false,\"info\":\"系统报错了，提交预习失败！\"}");
end