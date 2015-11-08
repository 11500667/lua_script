--[[
@Author chuzheng
@date 2014-12-18
@测试数据
功能：创建预习
--]]
local say = ngx.say;
local preparetionModel = require "yxx.preparation.model.Model";
local parameterUtil = require "yxx.tool.ParameterUtil";
local yx_id = parameterUtil:getStrParam("yx_id",'');--预习ID
if string.len(yx_id) == 0 then
    say("{\"success\":false,\"info\":\"yx_id不能为空!\"}");
    return;
end

local sucess = preparetionModel:delYxInfo(yx_id,2);
if not sucess then
    say("{\"success\":false,\"info\":\"预习删除失败！\"}");
else
    say("{\"success\":true,\"info\":\"预习删除成功！\"}");
end