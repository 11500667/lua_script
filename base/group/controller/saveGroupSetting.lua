-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 设置群组是否允许申请加入
-- 日期：2015年8月5日
-- -----------------------------------------------------------------------------------

local groupId = getParamToNumber("groupId");
local bRequest = getParamToNumber("b_request");

if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数group_id不能为空！\"}");
    return;
elseif bRequest == nil then
    ngx.print("{\"success\":false,\"info\":\"参数b_request不能为空！\"}");
    return;
end

local groupModel = require "base.group.model.Group";
local result     = groupModel.setBRequest(groupId, bRequest);

local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "保存设置成功";
else
    responseJson["info"] = "保存设置失败";
end

ngx.print(encodeJson(responseJson));