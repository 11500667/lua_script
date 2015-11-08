-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 设置成员类型（普通成员、群管理员）
-- 日期：2015年8月5日
-- -----------------------------------------------------------------------------------

local memberId   = getParamToNumber("memberId");
local memberType = getParamToNumber("memberType");
local groupName  = getParamByName("groupName");

if memberId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数memberId 不能为空！\"}");
    return;
elseif memberType == nil then
    ngx.print("{\"success\":false,\"info\":\"参数memberType不能为空！\"}");
    return;
end

local memberProps = {};
memberProps["id"]          = memberId;
memberProps["member_type"] = memberType;

local memberModel = require "base.group.model.Member";
local result      = memberModel.updateMember(memberProps);

local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "设置成功";
else
    responseJson["info"] = "设置失败";
end

ngx.print(encodeJson(responseJson));