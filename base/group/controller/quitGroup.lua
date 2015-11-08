-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 退出群组
-- 日期：2015年8月5日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local memberModel = require "base.group.model.Member";
local personModel = require "base.person.model.PersonInfoModel";
local cacheUtil   = require "common.CacheUtil";

local memberId    = getParamToNumber("memberId");
local memberType  = getParamToNumber("memberType");
local groupId     = getParamToNumber("groupId");

if memberId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数memberId不能为空！\"}");
    return;
elseif groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
end

local memberInfo = memberModel.getById(memberId);
if memberInfo == nil then
    ngx.print("{\"success\":false,\"info\":\"该成员不存在！\"}");
    return;
end

local personId   = memberInfo["person_id"];
local identityId = memberInfo["identity_id"];
local groupId    = memberInfo["group_id"];

local memberProps        = {};
memberProps["id"] = memberId;
memberProps["b_use"]     = 0;

-- 删除成员
local result = memberModel.updateMember(memberProps);
ngx.log(ngx.ERR, "[sj_log] -> [退出群组] -> [result] -> ", result);

-- 删除该用户中group_[person_id]_[identity_id] 和 group_[person_id]_[identity_id] 两个缓存中对应群组的ID
cacheUtil: srem("group_" .. personId .. "_" .. identityId, groupId);
cacheUtil: srem("group_" .. personId .. "_" .. identityId .. "_real", groupId);

local responseJson = {}
responseJson["success"] = true;   
if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.print(encodeJson(responseJson));