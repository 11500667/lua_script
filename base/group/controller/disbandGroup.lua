-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 解散群组
-- 日期：2015年8月8日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local groupId    = getParamToNumber("groupId");

if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
end

local groupModel = require "base.group.model.Group";
-- 删除成员
local result = groupModel.disbandGroup(groupId);

local responseJson = {};
responseJson["success"] = true;
if not result then
    responseJson["info"] = "解散群组失败";
else
    responseJson["info"] = "解散群组成功";
end

ngx.print(encodeJson(responseJson));