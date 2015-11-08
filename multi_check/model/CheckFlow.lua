--[[
    申健  2015-06-03
    描述：审核流程的基础函数类
]]

local _CheckFlow = {};


---------------------------------------------------------------------------
--[[
    局部函数：根据审核路径和单位类型获取该单位的状态
    作者：   申健 2015-03-09
    参数：   unitType              单位类型：1省、2市、3区、4总校、5分校
    参数：      checkPath          审核路径
    返回值1：boolean            操作是否成功 true成功，false失败
    返回值2：操作成功时返回单位的审核状态，操作失败时返回错误信息
]]
local function getByCheckId(self, checkId)
    
    local querySql = "SELECT ID, CHECK_ID, UNIT_ID, UNIT_TYPE, CHECK_STATUS, PERSON_ID, IDENTITY_ID, DATE_FORMAT(CHECK_TIME, '%Y-%m-%d %H:%i:%s') AS CHECK_TIME, CHECK_MSG, UPDATE_TS FROM T_BASE_CHECK_FLOW WHERE CHECK_ID=" .. checkId .. " ORDER BY CHECK_TIME DESC;";

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);

    if not queryResult then
        return false;
    end

    local personInfoModel = require "base.person.model.PersonInfoModel";
    local CacheUtil       = require "common.CacheUtil";
    local resultListObj   = {};

    for index = 1, #queryResult do
        local record      = queryResult[index];
        
        local unitId      = record["UNIT_ID"];
        local unitType    = record["UNIT_TYPE"];
        local checkStatus = record["CHECK_STATUS"];
        local personId    = tonumber(record["PERSON_ID"]);
        local identityId  = tonumber(record["IDENTITY_ID"]);
        local checkTime   = record["CHECK_TIME"];
        local checkMsg    = record["CHECK_MSG"];
        local personName  = "";
        if personId ~= 0 then
            personName  = personInfoModel: getPersonName(personId, identityId);
        else
            personName  = "无";
        end

        local unitName = CacheUtil: hget("t_base_organization_" .. unitId, "org_name");

        local resultObj = {};
        resultObj.person_id    = personId;
        resultObj.identity_id  = identityId;
        resultObj.person_name  = personName;
        resultObj.unit_id      = unitId;
        resultObj.unit_name    = unitName;
        resultObj.check_status = checkStatus;
        resultObj.check_time   = checkTime;
        resultObj.check_msg    = checkMsg;

        table.insert(resultListObj, resultObj);
    end

    return resultListObj;
end

_CheckFlow.getByCheckId = getByCheckId;
---------------------------------------------------------------------------

return _CheckFlow;