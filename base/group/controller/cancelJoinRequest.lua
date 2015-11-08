-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 取消入群申请
-- 日期：2015年8月12日
-- 作者：申健
-- -----------------------------------------------------------------------------------

local memberModel = require "base.group.model.Member";
local cacheUtil   = require "common.CacheUtil";

local memberId    = getParamToNumber("memberId");
if memberId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数memberId不能为空！\"}");
    return;
end

local memberInfo = memberModel.getById(memberId);
if memberInfo == nil then
    ngx.print("{\"success\":false,\"info\":\"该成员不存在！\"}");
    return;
end

local groupId        = memberInfo["group_id"];
local memberProps    = {};
memberProps["id"]    = memberId;
memberProps["b_use"] = 0;

-- 删除成员
local result = memberModel.updateMember(memberProps);
ngx.log(ngx.ERR, "[sj_log] -> [取消申请] -> [result] -> ", result);

local responseJson = {}
responseJson["success"] = true;   
if result then
    responseJson["info"] = "入群申请已被取消";
else
    responseJson["info"] = "操作失败，请稍候重试";
end

ngx.print(encodeJson(responseJson));