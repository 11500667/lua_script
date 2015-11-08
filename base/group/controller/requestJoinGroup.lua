-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 提交入群申请
-- 日期：2015年8月5日
-- 作者：申健
-- -----------------------------------------------------------------------------------

local groupId      = getParamToNumber("groupId");
local checkContent = getParamByName("checkContent");
local personId     = getCookieToNumber("person_id");
local identityId   = getCookieToNumber("identity_id");

if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
elseif checkContent == nil then
    ngx.print("{\"success\":false,\"info\":\"参数checkContent不能为空！\"}");
    return;
end

local personModel = require "base.person.model.PersonInfoModel";
local personInfo  = personModel: getPersonDetail(personId, identityId);

local memberProps  = {};
memberProps["group_id"]      = groupId;
memberProps["person_id"]     = personId;
memberProps["identity_id"]   = identityId;
memberProps["check_content"] = checkContent;
memberProps["state_id"]      = 0;            -- 审核状态：0未审核，1审核通过，2审核未通过
memberProps["b_use"]         = 1;            -- 停用状态：启用、停用
memberProps["apply_time"]    = os.date("%Y-%m-%d %H:%M:%S");
memberProps["check_time"]    = '1990-01-01 00:00:00';
memberProps["quit_time"]     = '1990-01-01 00:00:00';
memberProps["member_type"]   = 2;            -- 普通成员
memberProps["bureau_id"]     = personInfo["school_id"];


local memberModel = require "base.group.model.Member";
local result      = memberModel.saveNewRecord(memberProps);

local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "申请发送成功";
else
    responseJson["info"] = "申请发送失败";
end

ngx.print(encodeJson(responseJson));