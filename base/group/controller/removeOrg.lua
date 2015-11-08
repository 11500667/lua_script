--[[
#陈续刚 2015-08-06
#描述：查询群组成员
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say

local ID      = getParamToNumber("ID");


if ID == nil then
    ngx.print("{\"success\":false,\"info\":\"参数ID不能为空！\"}");
    return;
end

local groupModel  = require "base.group.model.groupMember";
local result = groupModel.removeOrg(ID);
local returnjson={}
returnjson.success = true
returnjson.info = "移除群组成员成功！"
if not result then 
	returnjson.success = false
	returnjson.info = "移除群组成员失败！"
end
say(cjson.encode(returnjson))