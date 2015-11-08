--[[
#陈续刚 2015-09-11
#描述：查询群组成员，给家校通使用
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say

local groupId      = getParamToNumber("groupId");
local app_type     = getParamToNumber["app_type"];--1 云版2 局版

if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
elseif app_type == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 app_type 不能为空！\"}");
    return;
end

local groupModel  = require "base.group.model.groupMember";
local result,returnjson = groupModel.getGroupMumberForApp(groupId,app_type);
if not result then 
	local returnjson={}
	returnjson.success = false
	returnjson.info = "获取群组成员失败！"
end
say(cjson.encode(returnjson))