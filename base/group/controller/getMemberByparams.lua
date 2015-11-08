--[[
#陈续刚 2015-08-06
#描述：查询群组成员
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say

local groupId      = getParamToNumber("groupId");
local nodeId       = getParamToNumber("nodeId");
local rangeType    = getParamToNumber("rangeType");
local orgType      = getParamToNumber("orgType");
local keyword 	   = getParamByName("keyword");
local pageNumber   = getParamToNumber("pageNumber");
local pageSize     = getParamToNumber("pageSize");
local member_type  = getParamToNumber("member_type");
local stage_id     = getParamToNumber("stage_id");
local subject_id   = getParamToNumber("subject_id");

if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
elseif nodeId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数nodeId不能为空！\"}");
    return;
elseif rangeType == nil then
    ngx.print("{\"success\":false,\"info\":\"参数rangeType不能为空！\"}");
    return;
elseif orgType == nil then
    ngx.print("{\"success\":false,\"info\":\"参数orgType不能为空！\"}");
    return;
elseif keyword == nil then
    ngx.print("{\"success\":false,\"info\":\"参数keyword不能为空！\"}");
    return;
elseif pageSize == nil then
    ngx.print("{\"success\":false,\"info\":\"参数pageSize不能为空！\"}");
    return;
elseif pageNumber == nil then
    ngx.print("{\"success\":false,\"info\":\"参数pageNumber不能为空！\"}");
    return;
elseif member_type == nil then
    ngx.print("{\"success\":false,\"info\":\"参数member_type不能为空！\"}");
    return;
elseif stage_id == nil then
    ngx.print("{\"success\":false,\"info\":\"参数stage_id不能为空！\"}");
    return;
elseif subject_id == nil then
    ngx.print("{\"success\":false,\"info\":\"参数subject_id不能为空！\"}");
    return;
end

local groupModel  = require "base.group.model.groupMember";
local result,returnjson = groupModel.getMemberByparams(groupId,nodeId,rangeType,orgType,keyword,pageNumber,pageSize,member_type,stage_id,subject_id);
if not result then 
	local returnjson={}
	returnjson.success = false
	returnjson.info = "获取群组成员失败！"
end
say(cjson.encode(returnjson))