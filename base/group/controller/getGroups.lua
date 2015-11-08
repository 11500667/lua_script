--[[
#陈续刚 2015-08-06
#描述：给群组添加人员时，获取群组数据
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say
--personId,identity_id,plat_type,group_type,use_range
local personId      = getParamToNumber("personId");
local identity_id 	   = getParamToNumber("identity_id");
local plat_type   = getParamToNumber("plat_type");
local group_type     = getParamToNumber("group_type");
local use_range  = getParamToNumber("use_range");

--ngx.log(ngx.ERR, "cxg_log =====>"..personId);
if personId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数personId不能为空！\"}");
    return;
elseif identity_id == nil then
    ngx.print("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
    return;
elseif plat_type == nil then
    ngx.print("{\"success\":false,\"info\":\"参数plat_type不能为空！\"}");
    return;
elseif group_type == nil then
    ngx.print("{\"success\":false,\"info\":\"参数group_type不能为空！\"}");
    return;
elseif use_range == nil then
    ngx.print("{\"success\":false,\"info\":\"参数use_range不能为空！\"}");
    return;
end

local groupModel  = require "base.group.model.groupMember";
local result ,returnjson   = groupModel.getGroups(personId,identity_id,plat_type,group_type,use_range);
if not result then 
	local returnjson = {}
	returnjson.success = false
	returnjson.info = "获取群组失败！"
end
say(cjson.encode(returnjson))