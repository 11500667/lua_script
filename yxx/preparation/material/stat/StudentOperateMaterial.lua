--[[
@Author cuijinlong
@date 2015-9-1
功能：学生查看预习统计
--]]
local say = ngx.say;
local MaterialModel = require "yxx.preparation.material.model.MaterialModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local person_id = parameterUtil:getStrParam("person_id","");--人员ID
local identity_id = parameterUtil:getStrParam("identity_id","");--人员身份
local material_id = parameterUtil:getStrParam("material_id","");--预习素材ID
local operate_type = parameterUtil:getStrParam("operate_type","");--操作 1:浏览  2：讨论  3：下载

if string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"person_id不能为空!\"}");
    return;
end

if string.len(identity_id) == 0 then
    say("{\"success\":false,\"info\":\"identity_id不能为空!\"}");
    return;
end

if string.len(material_id) == 0 then
    say("{\"success\":false,\"info\":\"material_id不能为空!\"}");
    return;
end

if string.len(operate_type) == 0 then
    say("{\"success\":false,\"info\":\"operate_type不能为空!\"}");
    return;
end
MaterialModel:setStatMaterialOperate(person_id,identity_id,material_id,operate_type);
say("{\"success\":true,\"info\":\"本次操作已加入统计！\"}")