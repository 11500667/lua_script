-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 获取入群申请列表
-- 日期：2015年8月5日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local memberModel = require "base.group.model.Member";

local groupId      = getParamToNumber("groupId");
local stateId      = getParamToNumber("stateId");
local pageNumber   = getParamToNumber("pageNumber");
local pageSize     = getParamToNumber("pageSize");

local personId     = getCookieToNumber("person_id");
local identityId   = getCookieToNumber("identity_id");

if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
elseif stateId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数stateId不能为空！\"}");
    return;
elseif pageNumber == nil then
    ngx.print("{\"success\":false,\"info\":\"参数pageNumber不能为空！\"}");
    return;
elseif pageSize == nil then
    ngx.print("{\"success\":false,\"info\":\"参数pageSize不能为空！\"}");
    return;
end

local queryCondition  = {};
queryCondition["personId"]   = personId;
queryCondition["identityId"] = identityId;
queryCondition["groupId"]    = groupId;
queryCondition["stateId"]    = stateId;
queryCondition["pageNumber"] = pageNumber;
queryCondition["pageSize"]   = pageSize;

local responseJson = memberModel.queryMember(queryCondition);
ngx.print(encodeJson(responseJson));