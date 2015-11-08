-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 审核入群申请
-- 日期：2015年8月7日
-- 作者：申健
-- -----------------------------------------------------------------------------------

local memberModel = require "base.group.model.Member";
local cacheUtil   = require "common.CacheUtil";

local memberId    = getParamToNumber("memberId");
local checkResult = getParamByName("checkResult");
local groupName   = getParamToNumber("groupName");

if memberId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数memberId不能为空！\"}");
    return;
elseif checkResult == nil then
    ngx.print("{\"success\":false,\"info\":\"参数checkResult不能为空！\"}");
    return;
end

local memberInfo = memberModel.getById(memberId);

-- 修改 T_BASE_GROUP_MEMBER_NEW 表中对应用户的 state_id
local result;
local memberProps = {};
memberProps["id"] = memberId;
if checkResult == "true" then
    memberProps["state_id"] = 1; -- 审核通过，修改 state_id 的值为1
    result = memberModel.updateMember(memberProps);
    --todo 如果审核通过，向redis缓存 group_[person_id]_[identity_id] 中写入当前群组ID
    cacheUtil: sadd("group_" .. memberInfo["person_id"] .. "_" .. memberInfo["identity_id"], memberInfo["group_id"]);
    cacheUtil: sadd("group_" .. memberInfo["person_id"] .. "_" .. memberInfo["identity_id"] .. "_real", memberInfo["group_id"]);
else
    memberProps["state_id"] = 2; -- 审核未通过, 删除成员记录
    result = memberModel.deleteById(memberId);
end

local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.print(encodeJson(responseJson));