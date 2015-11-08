--[[
#申健 2015-05-25
#描述：试题共享权限设置的基础函数
]]

local _ShareAuth = {};


---------------------------------------------------------------------------
--[[
    局部函数：访问其它请求，并将返回的值组装成table对象
    参数：url           接口地址
    参数：paramStr          参数字符串
    参数：methodType    请求方式：GET 或 POST
]]
local function _getResponseJson(url, paramStr, methodType)
    local response;
    if methodType == "GET" then
    
        response = ngx.location.capture(url .. "?" .. paramStr, {
            method = ngx.HTTP_GET
        });
        
    elseif methodType == "POST" then
    
        response = ngx.location.capture(url, {
            method = ngx.HTTP_POST,
            body = paramStr
        });
    end
    
    if response.status == 200 then
        local cjson = require "cjson";
        local responseJson = cjson.decode(response.body);
        ngx.log(ngx.ERR, "===> 调用接口的返回值 ===> " , response.body);
        return responseJson;
    else
        return { success=true, info="访问请求失败！"};
    end
end 

---------------------------------------------------------------------------

--[[
    局部函数：保存共享权限
    作者：    申健             2015-05-25
    参数：    paramJson        参数对象
    返回值：  boolean          true是审核人员，false不是审核人员
]]
local function saveShareAuth(self, paramJson) 
    
    local unitId       = paramJson.unit_id;
    local personId     = paramJson.person_id;
    local identityId   = paramJson.identity_id;
    local personName   = paramJson.person_name;
    local authList     = paramJson.subject_List;
    
    local DBUtil = require "common.DBUtil";
    
    local sqlTab = {};
    local sql    = "";
    
    -- 判断用户是否存在
    local isPersonExist = self: isPersonExist(personId, identityId);
    
    if isPersonExist then
        -- 删除用户与科目的关联关系
        sql = "DELETE FROM T_BASE_SHARE_AUTH_SUBJECT WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
        table.insert(sqlTab, sql);
    else
        -- 获取调用此请求的方式GET/POST
        local request_method = ngx.var.request_method;
        -- 要访问的接口url
        local url      = "/dsideal_yy/management/person/getOrgInfoByPerson";
        -- 调用接口所传递的参数
        local paramStr = "person_id=".. personId .. "&identity_id=" .. identityId .. "&type=0";
        
        local responseJson  = _getResponseJson(url, paramStr, request_method);
        local provinceName  = responseJson.province_name;
        local cityName      = responseJson.city_name;
        local districtName  = responseJson.district_name;
        local schoolName    = responseJson.school_name;
        local orgName       = responseJson.org_name;
        
        sql = "INSERT INTO T_BASE_SHARE_AUTH (UNIT_ID, PERSON_ID, IDENTITY_ID, PERSON_NAME, CREATE_TIME, PROVINCE_NAME, CITY_NAME, DISTRICT_NAME, SCHOOL_NAME, ORG_NAME ) VALUES (" .. unitId .. ", " .. personId .. "," .. identityId .. ",'" .. personName .. "', NOW(), '" .. provinceName .. "', '" .. cityName .. "', '" .. districtName .. "', '" .. schoolName .. "', '" .. orgName .. "');";
        
        table.insert(sqlTab, sql);
    end
        
    -- 循环前台发送过来的学科数组，获取学科信息
    for index=1, #authList do
        
        local authObj     = authList[index];
        local objType     = 2;
        local stageId     = authObj.stage_id;
        local stageName   = authObj.stage_name;
        local subjectId   = authObj.subject_id;
        local subjectName = authObj.subject_name;
        
        -- 重新插入审核人员与科目的关联关系
        sql = "INSERT INTO T_BASE_SHARE_AUTH_SUBJECT (PERSON_ID, IDENTITY_ID, OBJ_TYPE, STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME) VALUES ( " ..
            personId .. "," .. identityId .. ", " .. objType .. ", " .. stageId .. ", '" .. 
            stageName .. "', " .. subjectId .. ", '" .. subjectName .. "');";
        table.insert(sqlTab, sql);
    end

    local result = DBUtil:batchExecuteSqlInTx(sqlTab, 50);
    return result;

end

_ShareAuth.saveShareAuth = saveShareAuth;

---------------------------------------------------------------------------

local function  isPersonExist(self, personId, identityId)
    
    local DBUtil = require "common.DBUtil";
    local sql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_SHARE_AUTH WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
    
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 执行sql出错， sql语句：[" .. sql .. "]");
        return false;
    end

    local rowCount = tonumber(queryResult[1]["TOTAL_ROW"]);
    if rowCount > 0 then
        return true;
    else
        return false;
    end
end

_ShareAuth.isPersonExist = isPersonExist;
---------------------------------------------------------------------------

local function getShareAuthList(self, unitId, pageNumber, pageSize)
    
    local DBUtil = require "common.DBUtil";
    local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_SHARE_AUTH WHERE UNIT_ID=" .. unitId;
    
    local countRes = DBUtil: querySingleSql(countSql);
    if not countRes then
        return {success=false, info="查询数据出错！"};
    end
    local totalRow  = tonumber(countRes[1]["TOTAL_ROW"]);
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
    local offset    = pageSize*pageNumber-pageSize;
    local limit     = pageSize;
    
    local querySql = "SELECT PERSON_ID, PERSON_NAME, IDENTITY_ID, PROVINCE_NAME, CITY_NAME, DISTRICT_NAME, SCHOOL_NAME, ORG_NAME FROM T_BASE_SHARE_AUTH WHERE UNIT_ID=" .. unitId .. " ORDER BY CREATE_TIME DESC LIMIT " .. offset .. "," .. limit;
    ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 获取共享权限列表， sql语句： " .. querySql);

    local quesyResult = DBUtil: querySingleSql(querySql);
    if not quesyResult then
        return {success=false, info="查询数据出错！"};
    end
    
    local resultListObj = {};
    for i = 1, #quesyResult do
        local record         = {};
        record.PERSON_ID     = quesyResult[i]["PERSON_ID"];
        record.PERSON_NAME   = quesyResult[i]["PERSON_NAME"];
        record.IDENTITY_ID   = quesyResult[i]["IDENTITY_ID"];
        record.PROVINCE_NAME = quesyResult[i]["PROVINCE_NAME"];
        record.CITY_NAME     = quesyResult[i]["CITY_NAME"];
        record.DISTRICT_NAME = quesyResult[i]["DISTRICT_NAME"];
        record.SCHOOL_NAME   = quesyResult[i]["SCHOOL_NAME"];
        record.ORG_NAME      = quesyResult[i]["ORG_NAME"];
        
        table.insert(resultListObj, record);
    end
    
    local resultJsonObj = {};
    resultJsonObj.success    = true;
    resultJsonObj.totalRow   = totalRow;
    resultJsonObj.totalPage  = totalPage;
    resultJsonObj.pageNumber = pageNumber;
    resultJsonObj.pageSize   = pageSize;
    resultJsonObj.table_List = resultListObj;
    
    return resultJsonObj;

end

_ShareAuth.getShareAuthList = getShareAuthList;
---------------------------------------------------------------------------
--[[
    局部函数：判断该教师可共享的科目
    作者：  申健          2015-05-25
    参数：  personId      教师人员ID
    参数：  identityId    教师的身份ID
    返回值：resultJsonObj 科目列表
]]
local function getAuthByPerson(self, personId, identityId)
    
    local DBUtil = require "common.DBUtil";
    
    -- 获取审核人员在指定单位下的可以审核的学科
    sql = "SELECT PERSON_ID, IDENTITY_ID, OBJ_TYPE, STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME FROM T_BASE_SHARE_AUTH_SUBJECT WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " ORDER BY STAGE_ID DESC;";
    
    ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 查询教师可共享的科目， sql语句：[", sql, "]");
    
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return {success=false, info="查询数据出错！"};
    end
    
    local resultListObj = {};
    for i=1, #queryResult do
        local record = {};
        record.OBJ_TYPE         = queryResult[i]["OBJ_TYPE"];
        record.STAGE_ID         = queryResult[i]["STAGE_ID"];
        record.STAGE_NAME       = queryResult[i]["STAGE_NAME"];
        record.SUBJECT_ID       = queryResult[i]["SUBJECT_ID"];
        record.SUBJECT_NAME     = queryResult[i]["SUBJECT_NAME"];
        
        table.insert(resultListObj, record);
    end
    
    local resultJsonObj = {};
    resultJsonObj.success           = true;
    resultJsonObj.subject_List      = resultListObj;
    
    return resultJsonObj;
end

_ShareAuth.getAuthByPerson = getAuthByPerson;

---------------------------------------------------------------------------
--[[
    描述：删除共享权限
    作者：申健         2015-05-25
    参数：delPerArray  待删除的参数对象
]]
local function delShareAuth(self, delPerArray)
    
    local DBUtil = require "common.DBUtil";
    
    -- sqlTab 用于保存需要批量执行的sql语句
    local sqlTab = {};
    for i=1, #delPerArray do
        local personId   = delPerArray[i]["person_id"];
        local identityId = delPerArray[i]["identity_id"];
        -- 删除审核人员
        local deleteSql = "DELETE FROM T_BASE_SHARE_AUTH WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
        table.insert(sqlTab, deleteSql);
        -- 删除审核人员和科目的关联关系
        deleteSql = "DELETE FROM T_BASE_SHARE_AUTH_SUBJECT WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
        table.insert(sqlTab, deleteSql);
    end
    
    local result = DBUtil:batchExecuteSqlInTx(sqlTab, 50);
    
    return result;
end

_ShareAuth.delShareAuth = delShareAuth;

---------------------------------------------------------------------------
--[[
    描述：判断用户是否有指定对象的共享权限
    作者：申健         2015-05-25
    参数：objType      资源类型：1资源，2试题，3试卷，4备课，5微课
    参数：personId     人员ID
    参数：identityId   身份ID
    参数：subjectId    科目ID
    返回：nil获取信息出错， true有共享权限， false没有共享权限
]]
local function canShare(self, objType, personId, identityId, subjectId)
    
    local DBUtil = require "common.DBUtil";
    local sql    = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_SHARE_AUTH_SUBJECT WHERE OBJ_TYPE=" .. objType .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " AND SUBJECT_ID=" .. subjectId .. ";";
    ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 判断指定科目下是否有共享权限的sql语句：[[[", sql, "]]]");
    local queryResult = DBUtil: querySingleSql(sql);
    local cjson = require "cjson";
    -- ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> queryResult:[", cjson.encode(queryResult), "]");
    if not queryResult then
        return nil;
    end

    local rowCount = tonumber(queryResult[1]["TOTAL_ROW"]);
    -- ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> rowCount:[", rowCount, "]");
    if rowCount > 0 then 
        return true;
    else
        return false;
    end
end

_ShareAuth.canShare = canShare;

---------------------------------------------------------------------------

return _ShareAuth;