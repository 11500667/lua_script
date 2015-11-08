--[[
#陈续刚 2015-08-06
#描述：机构群组添加成员
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say

--groupId,currentTime,ts,oids
local groupId      = getParamToNumber("groupId");
--local oids = ngx.unescape_uri(args["oids"])
local oids = getParamByName("oids")
if oids then
	oids = cjson.decode(oids)
end
if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
--[[elseif oids == nil then
    ngx.print("{\"success\":false,\"info\":\"参数oids不能为空！\"}");
    return;]]
end
local currentTime = os.date("%Y-%m-%d %H:%M:%S")
local n = ngx.now();
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts = ts..string.rep("0",19-string.len(ts));

local groupModel  = require "base.group.model.groupMember";
local result = groupModel.addMemberByOrg(groupId,currentTime,ts,oids);
local returnjson={}
if result then 
	returnjson.success = true
	returnjson.info = "群组添加成员成功！"
else
	returnjson.success = false
	returnjson.info = "群组添加成员失败！"
end
say(cjson.encode(returnjson))