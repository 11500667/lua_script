-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 成员的基础接口
-- 日期：2015年8月4日
-- -----------------------------------------------------------------------------------
local SSDBUtil = require "common.SSDBUtil";
local DBUtil   = require "common.DBUtil";
local tsModel  = require "resty.TS";


local _Member = {}

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 保存入群申请
-- 日    期： 2015年8月4日
-- 参    数： paramTable 存储参数的table对象
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function saveJoinRequest(paramTable)
    
    
end

_Member.saveJoinRequest = saveJoinRequest;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 获取T_BASE_GROUP_MEMBER_NEW表的新的ID（从SSDB中获取）
-- 日    期： 2015年8月4日
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function getNewRecordPk()
    return SSDBUtil: incr("t_base_group_member_new_pk");
end

_Member.getNewRecordPk = getNewRecordPk;


-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 获取指定群组的成员
-- 日    期： 2015年8月4日
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function queryMember(paramTable)
    local groupId     = paramTable["groupId"];
    local stateId     = paramTable["stateId"];
    local pageNumber  = paramTable["pageNumber"];
    local pageSize    = paramTable["pageSize"];
    local personId    = paramTable["personId"];
    local identityId  = paramTable["identityId"];
    
    local personModel = require "base.person.model.PersonInfoModel";
    local personInfo  = personModel: getPersonDetail(personId, identityId);
    local orgId       = personInfo["org_id"];

    local conditionSegement = " FROM t_base_group_member_new member LEFT OUTER JOIN t_base_person person ON member.PERSON_ID = person.PERSON_ID AND member.IDENTITY_ID = person.IDENTITY_ID LEFT OUTER JOIN t_base_student student ON member.person_id = student.student_id AND member.identity_id = 6 LEFT OUTER JOIN t_base_organization bureau ON member.bureau_id = bureau.org_id LEFT OUTER JOIN t_base_organization org ON person.org_id = org.org_id LEFT OUTER JOIN t_base_class class ON student.class_id = class.class_id WHERE 1=1 ";
    if groupId ~= nil then
        conditionSegement = conditionSegement .. " AND member.GROUP_ID = " .. groupId ;
    end
    if stateId ~= nil then
        conditionSegement = conditionSegement .. " AND member.STATE_ID = " .. stateId ;
    end
    local countSql  = "SELECT COUNT(1) AS ROW_COUNT " .. conditionSegement;
    local countRes  = DBUtil: querySingleSql(countSql);
    if not countRes then
        return false;
    end
    local totalRow  = countRes[1]["ROW_COUNT"];
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
    local offset    = pageSize*pageNumber-pageSize;
    local limit     = pageSize;

    local querySql  = "SELECT MEMBER.ID AS member_id, MEMBER.PERSON_ID AS person_id, MEMBER.IDENTITY_ID AS identity_id, MEMBER.APPLY_TIME AS apply_time, MEMBER.CHECK_CONTENT AS check_content, MEMBER.MEMBER_TYPE AS member_type, person.PERSON_NAME AS person_name, student.STUDENT_NAME AS student_name, bureau.ORG_ID AS bureau_id, bureau.ORG_NAME AS bureau_name, org.ORG_ID AS org_id, org.ORG_NAME AS org_name, class.CLASS_ID AS class_id, class.CLASS_NAME AS class_name " .. conditionSegement .. " ORDER BY member.APPLY_TIME ASC LIMIT " .. offset .. "," .. limit .. ";";
    local queryRes  = DBUtil: querySingleSql(querySql);
    if not queryRes then
        return false;
    end

    local resultJson         = {};
    resultJson["success"]    = true;
    resultJson["totalRow"]   = totalRow;
    resultJson["totalPage"]  = totalPage;
    resultJson["pageNumber"] = pageNumber;
    resultJson["pageSize"]   = pageSize;

    local resultList = {};
    for index, record in ipairs(queryRes) do
        local tempRecord = {};
        tempRecord["member_id"]     = record["member_id"];
        tempRecord["person_id"]     = record["person_id"];
        tempRecord["person_name"]   = record["person_name"];
        tempRecord["identity_id"]   = record["identity_id"];
        tempRecord["bureau_id"]     = record["bureau_id"];
        tempRecord["bureau_name"]   = record["bureau_name"];
        tempRecord["apply_time"]    = record["apply_time"];
        tempRecord["check_content"] = record["check_content"];
        tempRecord["member_type"]   = record["member_type"];

        if record["identity_id"] == 5 then
            tempRecord["org_id"]   = record["org_id"];
            tempRecord["org_name"] = record["org_name"];
        elseif record["identity_id"] == 6 then
            tempRecord["org_id"]   = record["class_id"];
            tempRecord["org_name"] = record["class_name"];
        end 
        table.insert(resultList, tempRecord);
    end
    resultJson["table_List"]   = resultList;

    return resultJson;
end

_Member.queryMember = queryMember;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 保存新的成员记录
-- 日    期： 2015年8月5日
-- 参    数： paramTable 存储参数的table对象
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function saveNewRecord(paramTable)
    local newId      = _Member.getNewRecordPk();
    local groupId    = paramTable["group_id"];
    local personId   = paramTable["person_id"];
    local identityId = paramTable["identity_id"];
    local checkMsg   = paramTable["check_content"];
    local stateId    = paramTable["state_id"];
    local bUse       = paramTable["b_use"];
    local applyTime  = paramTable["apply_time"];
    local checkTime  = paramTable["check_time"];
    local quitTime   = paramTable["quit_time"];
    local memberType = paramTable["member_type"];
    local bureauId   = paramTable["bureau_id"];
    local currentTS  = tsModel.getTs();

    local insertSql = "INSERT INTO T_BASE_GROUP_MEMBER_NEW (GROUP_ID, PERSON_ID, IDENTITY_ID, CHECK_CONTENT, STATE_ID, B_USE, APPLY_TIME, CHECK_TIME, QUIT_TIME, MEMBER_TYPE, BUREAU_ID, TS) VALUES (" .. groupId .. ", " .. personId .. ", " .. identityId .. ", " .. ngx.quote_sql_str(checkMsg) .. ", " .. stateId .. ", " .. bUse .. ", " .. ngx.quote_sql_str(applyTime) .. ", " .. ngx.quote_sql_str(checkTime) .. ", " .. ngx.quote_sql_str(quitTime) .. ", " .. memberType .. ", " .. bureauId .. ", " .. currentTS .. ") ;";
    ngx.log(ngx.ERR, "[sj_log] -> [群组] -> [保存新的成员记录] -> sql: [", insertSql, "]");
    local result = DBUtil: querySingleSql(insertSql);
    if not result then
        return false, "执行sql语句报错， sql语句：[", insertSql, "]";
    else
        return true;
    end
end

_Member.saveNewRecord = saveNewRecord;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 更新成员记录
-- 日    期： 2015年8月5日
-- 参    数： paramTable 存储参数的table对象
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function updateMember(paramTable)
    local memberId = paramTable["id"];
    if memberId == nil or memberId == ngx.null then
        return false, "id不能为空";
    end

    local fieldTable = {};

    local whereSql = "";
    local stateId  = paramTable["state_id"];
    if stateId ~= nil and stateId ~= ngx.null then
        fieldTable["STATE_ID"] = stateId;
    end

    local bUse = paramTable["b_use"];
    if bUse ~= nil and bUse ~= ngx.null then
        fieldTable["B_USE"] = bUse;
    end

    local applyTime = paramTable["apply_time"];
    if applyTime ~= nil and applyTime ~= ngx.null then
        fieldTable["APPLY_TIME"] = ngx.quote_sql_str(applyTime);
    end

    local checkTime = paramTable["check_time"];
    if checkTime ~= nil and checkTime ~= ngx.null then
        fieldTable["CHECK_TIME"] = ngx.quote_sql_str(checkTime);
    end

    local quitTime = paramTable["quit_time"];
    if quitTime ~= nil and quitTime ~= ngx.null then
        fieldTable["QUIT_TIME"] = ngx.quote_sql_str(quitTime);
    end

    local memberType = paramTable["member_type"];
    if memberType ~= nil and memberType ~= ngx.null then
        fieldTable["MEMBER_TYPE"] = memberType;
    end

    local currentTS  = tsModel.getTs();
    fieldTable["TS"] = currentTS;

    local updateSql = "UPDATE T_BASE_GROUP_MEMBER_NEW SET ";
    if next(fieldTable) ~= nil then
        for field, value in pairs(fieldTable) do
            updateSql = updateSql .. " " .. field .. " = " .. value .. ",";
        end
    else
        return false, "没有获取到需要更新的字段";
    end
    updateSql = string.sub(updateSql, 1, string.len(updateSql) - 1);
    updateSql = updateSql .. " WHERE ID = " .. memberId .. ";";

    ngx.log(ngx.ERR, "\n [sj_log] -> [更新成员信息] -> updateSql : [", updateSql, "] \n");

    local result = DBUtil: querySingleSql(updateSql);
    if not result then
        return false;
    else
        return true;
    end
end

_Member.updateMember = updateMember;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 删除群成员
-- 日    期： 2015年8月4日
-- 参    数： memberId 成员ID，对应T_BASE_GROUP_MEMBER_NEW 表的ID
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function deleteById(memberId)
    local sql = "DELETE FROM T_BASE_GROUP_MEMBER_NEW WHERE ID = " .. memberId;
    local result = DBUtil: querySingleSql(sql);
    if not result then
        return false;
    else
        return true;
    end
end

_Member.deleteById = deleteById;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 批量删除群成员
-- 日    期： 2015年8月5日
-- 参    数： memberIdTable 存储待删除的成员ID的table对象
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function deleteByIds(memberIdTable)
    if #memberIdTable > 0 then
        local sql = "DELETE FROM T_BASE_GROUP_MEMBER_NEW WHERE  ID IN (" .. table.concat(memberIdTable, ",") .. ");";
        local result = DBUtil: querySingleSql(sql);
        if not result then
            return false;
        else
            return true;
        end        
    end
    return true;    
end

_Member.deleteByIds = deleteByIds;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 根据person_id 和 identity_id 删除群成员
-- 日    期： 2015年8月5日
-- 参    数： memberIdTable 存储待删除的成员ID的table对象
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function deleteByPersonId(groupId, personId, identityId)
    if groupId == nil or personId == nil or identityId == nil then
        return false, "参数不能为空";
    end

    local sql = "DELETE FROM T_BASE_GROUP_MEMBER_NEW WHERE GROUP_ID=" .. groupId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
    local result = DBUtil: querySingleSql(sql);
    if not result then
        return false;
    else
        return true;
    end     
end

_Member.deleteByPersonId = deleteByPersonId;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 删除指定群组下的所有成员
-- 日    期： 2015年8月5日
-- 参    数： groupId 群组ID
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function deleteByGroup(groupId)
    if groupId == nil then
        return false, "参数不能为空";
    end

    local sql = "DELETE FROM T_BASE_GROUP_MEMBER_NEW WHERE GROUP_ID=" .. groupId .. ";";
    local result = DBUtil: querySingleSql(sql);
    if not result then
        return false;
    else
        return true;
    end     
end

_Member.deleteByGroup = deleteByGroup;

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 设置成管理员
-- 日    期： 2015年8月4日
-- 参    数： paramTable 存储参数的table对象
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function set2Admin(paramTable)
    
    local sql = "UPDATE T_BASE_GROUP_MEMBER_NEW SET MEMBER_TYPE=" .. memberType .. " WHERE GROUP_ID";
    
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 根据ID获取成员记录
-- 日    期： 2015年8月8日
-- 参    数： memberId 成员的记录ID
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function getById(memberId)
    
    local sql = "select id, group_id, person_id, identity_id, check_content, state_id, b_use, DATE_FORMAT(apply_time, '%Y-%m-%d %H:%i:%S') AS apply_time, DATE_FORMAT(check_time, '%Y-%m-%d %H:%i:%S') AS check_time, DATE_FORMAT(quit_time, '%Y-%m-%d %H:%i:%S') AS quit_time, member_type, bureau_id, ts from t_base_group_member_new where id=" .. memberId .. ";";
    local queryRes = DBUtil: querySingleSql(sql);
    if not queryRes then 
        return false;
    end
    return queryRes[1];
end

_Member.getById = getById;

return _Member;