--[[
#陈续刚 2015-08-27
#描述：获取学校数据
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say

local provinceId      = getParamToNumber("provinceId");
local cityId      = getParamToNumber("cityId");
local districtId      = getParamToNumber("districtId");
local keyword 	   = getParamByName("keyword");
local pageNumber   = getParamToNumber("pageNumber");
local pageSize     = getParamToNumber("pageSize");
local register_flag     = getParamToNumber("register_flag");


if provinceId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 provinceId 不能为空！\"}");
    return;
elseif cityId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 cityId 不能为空！\"}");
    return;
elseif districtId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 districtId 不能为空！\"}");
    return;
elseif keyword == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 keyword 不能为空！\"}");
    return;
elseif pageSize == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 pageSize 不能为空！\"}");
    return;
elseif pageNumber == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 pageNumber 不能为空！\"}");
    return;
end

local regModel  = require "registered.ypt.model.register";
local result,returnjson = regModel.getSchByparams(provinceId,cityId,districtId,keyword,pageNumber,pageSize,register_flag);
if not result then 
	local returnjson={}
	returnjson.success = false
	returnjson.info = "获取学校数据失败！"
end
say(cjson.encode(returnjson))