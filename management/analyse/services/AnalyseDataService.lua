--[[
    #申健   2015-04-18
    #描述： 资源统计的服务类
]]
local strucModel = require "base.structure.model.Structure";
local DBUtil     = require "common.DBUtil";


local _AnalyseDataService = {};

local govIdFieldTab   = { "city_id", "district_id", "school_id", "personID" };
local govNameFieldTab = { "city_name", "district_name", "school_name", "personName" };

----------------------------------------------------------------------------------
--[[
	局部函数：插入统计基础数据（在用户上传文件成功后调用）
	作者：    申健 	        2015-04-17
	参数1：   stageId  	    学段ID
	参数2：   subjectId  	科目ID
	参数3：   platId  	    系统类型：1资源，2试卷，3试题，4备课，5微课
	参数4：   personId  	资源上传人的人员ID
	参数5：   identityId  	资源上传人的身份ID
	参数6：   dataCount  	上传的资源的数量
	参数7：   size  	    上传的资源的大小
	返回值1： boolean true插入数据成功，false插入数据失败
]]
local function insertAnalyseData(self, stageId, subjectId, platId, personId, identityId, dataCount, size, resIdInt, schemeId, structureId)

    local DBUtil     = require "multi_check.model.DBUtil";

    -- 获取用户端的个人信息：所在省、市、区、校的ID
    local personModel   = require "base.person.model.PersonInfoModel";
    local recordTable   = personModel: getPersonDetail(personId, identityId);
    recordTable.person_id       = personId;
    recordTable.identity_id     = identityId;
    recordTable.plat_id         = platId;
    recordTable.count           = dataCount;
    recordTable.size            = size;
    recordTable.stage_id        = stageId;
    recordTable.subject_id      = subjectId;
    recordTable.resource_id_int = resIdInt;

    local AnalyseDataM  = require "management.analyse.model.AnalyseDataModel";
    local keyMapService = require "management.analyse.services.AnalyseKeyMapService";
    local mapKey        = keyMapService: getKeyBySubject(subjectId);
    recordTable.map_key  = mapKey;

    local sqlTable = {};
    -- 获取插入组织机构（省市区）-> 下级单位统计结果的数据记录
    local sql = AnalyseDataM: getInsertGovSubjectSql(recordTable);
    table.insert(sqlTable, sql);

    -- 获取插入学校-> 个人统计结果的数据记录
    sql = AnalyseDataM: getInsertSchoolSubjectSql(recordTable);
    table.insert(sqlTable, sql);

    local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, 50);
    -- 将数据库连接返回连接池
    return boolResult;
end

_AnalyseDataService.insertAnalyseData = insertAnalyseData;

----------------------------------------------------------------------------------
--[[
	局部函数：插入统计基础数据（在用户上传文件成功后调用）
	作者：    申健 	        2015-04-17
	参数1：   stageId  	    学段ID
	参数2：   subjectId  	科目ID
	参数3：   platId  	    系统类型：1资源，2试卷，3试题，4备课，5微课
	参数4：   personId  	资源上传人的人员ID
	参数5：   identityId  	资源上传人的身份ID
	参数6：   dataCount  	上传的资源的数量
	参数7：   size  	    上传的资源的大小
	返回值1： boolean true插入数据成功，false插入数据失败
]]
local function insertPlatAnalyseData(self, stageId, subjectId, destOrgId, platId, personId, identityId, dataCount, size, objIdInt, objIdChar, resIdInt, schemeId, strucId)
    -- 多级审核中资源类型与资源统计的不一致
    local multiCheckType = {1,3,2,4,5};

    local DBUtil     = require "common.DBUtil";
    local StrucModel = require "base.structure.model.Structure";
    local strucCode  = StrucModel: getStrucCodeById(strucId);
    ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 获取STRUCTUER_ID为[", strucId, "]");
    strucCode = "," .. string.gsub(strucCode, "_", ",") .. ",";
    ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 获取STRUCTUER_ID为[", strucId, "]的节点的STRUCTURE_CODE -> [", strucCode, "]");

    -- 获取用户端的个人信息：所在省、市、区、校的ID
    local personModel   = require "base.person.model.PersonInfoModel";
    local recordTable   = personModel: getPersonDetail(personId, identityId);
    recordTable.person_id       = personId;
    recordTable.identity_id     = identityId;
    recordTable.plat_id         = multiCheckType[platId];
    recordTable.count           = dataCount;
    recordTable.size            = size;
    recordTable.stage_id        = stageId;
    recordTable.subject_id      = subjectId;
    recordTable.scheme_id       = schemeId;
    recordTable.structure_id    = strucId;
    recordTable.structure_code  = strucCode;
    recordTable.dest_org_id     = destOrgId;
    recordTable.obj_id_int      = objIdInt;
    recordTable.obj_id_char     = objIdChar;
    recordTable.obj_type        = multiCheckType[platId];
    recordTable.resource_id_int = resIdInt;
    
    local cjson = require "cjson";
--    ngx.log(ngx.ERR, "===> platId的值 ===> ", platId);
--    ngx.log(ngx.ERR, "===> 插入统计数据recordTable对象的值 ===> ", cjson.encode(recordTable));
    
    local AnalyseDataM  = require "management.analyse.model.AnalyseDataModel";
    local keyMapService = require "management.analyse.services.AnalyseKeyMapService";
    local mapKey        = recordTable.plat_id;
    recordTable.map_key  = mapKey;

    local sqlTable = {};
    -- 获取插入组织机构（省市区）-> 平台统计结果的数据记录
    local sql = AnalyseDataM: getInsertGovPlatSql(recordTable);
    table.insert(sqlTable, sql);

    -- 获取插入学校-> 个人， 按平台进行统计的数据记录
    sql = AnalyseDataM: getInsertPersonPlatSql(recordTable);
    table.insert(sqlTable, sql);

    -- 将数据库连接返回连接池
    return sqlTable;
end

_AnalyseDataService.insertPlatAnalyseData = insertPlatAnalyseData;

----------------------------------------------------------------------------------
--[[
	局部函数：插入按平台统计的数据
	作者：    申健 	        2015-04-24
	参数1：   stageId  	    学段ID
	参数2：   subjectId  	科目ID
	参数3：   platId  	    系统类型：1资源，2试卷，3试题，4备课，5微课
	参数4：   personId  	资源上传人的人员ID
	参数5：   identityId  	资源上传人的身份ID
	参数6：   dataCount  	上传的资源的数量
	参数7：   size  	    上传的资源的大小
	返回值1： boolean true插入数据成功，false插入数据失败
]]
local function getDelPlatAnalyseSql(self, objIdInt, objIdChar, objType, strucId, personId, identityId, destOrgIdArray)
    
    -- 多级审核中资源类型与资源统计的不一致
    local multiCheckType   = {1,3,2,4,5};
    
    local paramTable        = {};
    paramTable.obj_id_int   = objIdInt;
    paramTable.obj_id_char  = objIdChar
    paramTable.obj_type     = multiCheckType[objType];
    paramTable.structure_id = strucId;
    paramTable.person_id    = personId;
    paramTable.identity_id  = identityId;

    local analyseDataModel = require "management.analyse.model.AnalyseDataModel";
    local sqlTable = {};

    if destOrgIdArray ~= nil and destOrgIdArray ~= 0 then
        if type(destOrgIdArray) == "table" then
            for index = 1, #destOrgIdArray do
                paramTable.dest_org_id = destOrgIdArray[index];
                local sql      = analyseDataModel: getDeleteGovPlatSql(paramTable);
                table.insert(sqlTable, sql);

                sql = analyseDataModel: getDeletePersonPlatSql(paramTable);
                table.insert(sqlTable, sql);
            end
        elseif type(destOrgIdArray) == "number" then
            paramTable.dest_org_id = destOrgIdArray
            local sql = analyseDataModel: getDeleteGovPlatSql(paramTable);
            table.insert(sqlTable, sql);

            sql = analyseDataModel: getDeletePersonPlatSql(paramTable);
            table.insert(sqlTable, sql);
        end
    end
    return sqlTable;
end

_AnalyseDataService.getDelPlatAnalyseSql = getDelPlatAnalyseSql;

----------------------------------------------------------------------------------
--[[
	局部函数：获取根据科目和预留字段的映射关系，拼装统计sql语句的SELECT部分
	作者：    申健 	        2015-04-19
	参数1：   keyMapList  	科目的映射关系列表（LIST型）
	参数2：   keyMap  	    科目的映射关系（MAP型）
	返回值1： boolean true插入数据成功，false插入数据失败
]]
local function _getSubjectQueryFieldSql(keyMapList, keyMap)

    local countFieldList     = {};
    local sizeFieldList      = {};
    local querySql  = "'1' AS TEMP";
    for index = 1, #keyMapList do
        local mapKey = keyMapList[index]["MAP_KEY"];
        querySql = querySql .. ",IFNULL(SUM(V" .. mapKey .. "_COUNT), 0) AS V" .. mapKey .. "_COUNT"
        .. ",IFNULL(SUM(V" .. mapKey .. "_SIZE), 0) AS V" .. mapKey .. "_SIZE";

        table.insert(countFieldList, "V" .. mapKey .. "_COUNT");
        table.insert(sizeFieldList, "V" .. mapKey .. "_SIZE");
    end

    return querySql, countFieldList, sizeFieldList;
end

----------------------------------------------------------------------------------
--[[
	本地函数：获取指定机构的下级组织机构的列表
	作者：    申健 	        2015-04-19
	参数1：   govType  	    行政单位类型：1省，2市，3区，4校
	参数2：   unitId  	    单位ID
	返回值1： 组织机构列表
]]
local function _getOrg(govType, unitId, stageId)

    local cjson = require "cjson";

    if govType == 1 then -- 省

        local regionModel = require "base.region.model.RegionModel";
        local cityList    = regionModel: getCityByProvince(unitId);
        return true, cityList;

    elseif govType == 2 then -- 市

        local captureResponse = ngx.location.capture("/dsideal_yy/management/region/getDistrictByCity?city_id=" .. unitId, {
                method = ngx.HTTP_POST,
                body = "city_id=" .. unitId
            });
        if captureResponse.status == ngx.HTTP_OK then
            resultJson = cjson.decode(captureResponse.body);
            ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> captureResponse.body ===> ", captureResponse.body);
            return true, resultJson.table_list;
        else
            return false;
        end

    elseif govType == 3 then -- 区

        local captureResponse = ngx.location.capture("/dsideal_yy/management/region/getSchoolByDistrict?district_id=" .. unitId .. "&stage_id=" .. stageId, {
                method = ngx.HTTP_POST,
                body = "district_id=" .. unitId .. "&stage_id=" .. stageId
            });
        if captureResponse.status == ngx.HTTP_OK then
            resultJson = cjson.decode(captureResponse.body);
            ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> captureResponse.body ===> ", captureResponse.body);
            return true, resultJson.table_list;
        else
            return false;
        end
    end
end

----------------------------------------------------------------------------------
--[[
	本地函数：获取指定学校的所有教师
	作者：    申健 	        2015-04-19
	参数1：   schoolId  	学校ID
	返回值1： 人员列表
]]
local function _getTeacherBySchool(schoolId)

    local cjson = require "cjson";
    -- 判断是否为东师理想的学科人员
    local captureResponse;
    if ngx.var.request_method == "GET" then
        captureResponse = ngx.location.capture("/dsideal_yy/person/getPersonListBySch?school_id=" .. schoolId);
    else
        captureResponse = ngx.location.capture("/dsideal_yy/person/getPersonListBySch", {
                method = ngx.HTTP_POST,
                body = "school_id=" .. schoolId
            });
    end

    if captureResponse.status == ngx.HTTP_OK then
        resultJson = cjson.decode(captureResponse.body);
        ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> captureResponse.body ===> ", captureResponse.body);
        return true, resultJson.list;
    else
        return false;
    end
end

----------------------------------------------------------------------------------
--[[
	私有函数：封装统计结果的行
	作者：    申健 	        2015-04-19
	参数1：   record  	    从数据库中查询出的行（T_ANALYSE_GOV_SUBJECT）
	参数1：   govName  	    行政单位的名称
	参数2：   fieldList  	统计结果的字段列表
	参数2：   valueType  	1数量，2容量
	返回值1： valueTable    封装后的统计结果记录
]]
local function _getResultRecord(record, govId, govName, fieldList, valueType)

    local FileSizeM = require "common.FileSize";

    local valueTable = {};
    table.insert(valueTable, govName);
    table.insert(valueTable, govId);
    if record == nil or record == ngx.null then
        for fieldIndex = 1, #fieldList do
            table.insert(valueTable, 0);
        end
        table.insert(valueTable, 0);
    else
        local totalVal = 0;
        for fieldIndex = 1, #fieldList do
            local fieldName  = fieldList[fieldIndex];
            local fieldValue = tonumber(record[fieldName]);
            if valueType == 2 then 
                if fieldValue <= 0 then
                    fieldValue = 0;
                else
                    fieldValue = FileSizeM: getFileSize(fieldValue, 1);
                end
            end
            table.insert(valueTable, fieldValue);
            if fieldValue ~= nil then
                totalVal = totalVal + fieldValue;   
            end
        end
        table.insert(valueTable, totalVal);
    end
    return valueTable;
end

----------------------------------------------------------------------------------
--[[
	私有函数：获取按学段统计省（或市、区）的sql语句
	作者：    申健 	        2015-04-19
	返回值1： SQL语句
]]
local function _getAnalyseGovSql(govType, unitId, stageId, platId, startTime, endTime, querySql)

    local subSql    = "";
    local groupSql  = "";
    if govType == 1 then
        subSql   = subSql .. " AND PROVINCE_ID=" .. unitId;
        querySql = querySql .. ",CITY_ID AS GOV_ID"
        groupSql = " GROUP BY CITY_ID"; 
    elseif govType == 2 then
        subSql   = subSql .. " AND CITY_ID=" .. unitId;
        querySql = querySql .. ",DISTRICT_ID AS GOV_ID"
        groupSql = " GROUP BY DISTRICT_ID"; 
    elseif govType == 3 then
        subSql   = subSql .. " AND DISTRICT_ID=" .. unitId;
        querySql = querySql .. ",SCHOOL_ID AS GOV_ID"
        groupSql = " GROUP BY SCHOOL_ID"; 
    end

    local sql = "SELECT " .. querySql .. " FROM T_ANALYSE_GOV_SUBJECT WHERE 1=1 " .. subSql .." AND PLAT_ID=" .. platId .. " AND STAGE_ID=" .. stageId .. " "; 

    if startTime ~= nil and startTime ~= "" then
        sql = sql .. " AND DATE_TIME > '" .. startTime .. " 00:00:00' ";
    end
    if endTime ~= nil and endTime ~= "" then
        sql = sql .. " AND DATE_TIME < '" .. endTime .. " 23:59:59' ";
    end
    sql = sql .. groupSql.. ";";

    return sql;
end

----------------------------------------------------------------------------------
--[[
	私有函数：获取按学段统计学校下老师上传资源的sql语句
	作者：    申健 	        2015-04-19
	返回值1： SQL语句
]]
local function _getAnalyseSchoolSql(unitId, stageId, platId, startTime, endTime, querySql)

    local subSql   = " AND SCHOOL_ID=" .. unitId;
    local groupSql = " GROUP BY PERSON_ID"; 
    querySql = querySql .. ",PERSON_ID AS GOV_ID"

    local sql = "SELECT " .. querySql .. " FROM T_ANALYSE_SCHOOL_PERSON WHERE 1=1 " .. subSql .." AND PLAT_ID=" .. platId .. " AND STAGE_ID=" .. stageId .. " "; 

    if startTime ~= nil then
        sql = sql .. " AND DATE_TIME > '" .. startTime .. " 00:00:00' ";
    end
    if endTime ~= nil then
        sql = sql .. " AND DATE_TIME < '" .. endTime .. " 23:59:59' ";
    end
    sql = sql .. groupSql.. ";";

    return sql;
end

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-18
	参数1：   govType  	    行政单位类型：1省，2市，3区，4校
	参数2：   unitId  	    单位ID
    参数3：   platId  	    系统类型：1资源，2试卷，3试题，4备课，5微课
	参数4：   stageId  	    学段ID
	参数5：   subjectId  	科目ID
	参数6：   startTime  	开始时间
	参数7：   endTime  	    结束时间
	返回值1： boolean       true插入数据成功，false插入数据失败
]]
local function analyseDataByStage(self, govType, unitId, platId, stageId, startTime, endTime)

    local DBUtil 	= require "multi_check.model.DBUtil";
    local db 	 	= DBUtil: getDb();

    local resultObj = {};    
    local keyMapService      = require "management.analyse.services.AnalyseKeyMapService";
    local keyMapList, keyMap = keyMapService: getKeyMapByStage(stageId);
    local keyCount           = #keyMapList;

    local querySql, countFields, sizeFields = _getSubjectQueryFieldSql(keyMapList, keyMap);
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> countFields ===> ", cjson.encode(countFields));
    ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> sizeFields ===> ", cjson.encode(sizeFields));

    -- 获取统计的SQL语句
    local succFlag, govList, sql;
    if govType == 4 then -- 学校
        succFlag, govList  = _getTeacherBySchool(unitId);
        sql = _getAnalyseSchoolSql(unitId, stageId, platId, startTime, endTime, querySql);
    else
        succFlag, govList  = _getOrg(govType, unitId, stageId);
        sql = _getAnalyseGovSql(govType, unitId, stageId, platId, startTime, endTime, querySql);
    end
    ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> 统计的sql语句 ===> [", sql, "] <===");

    -- 执行SQL语句，查询统计结果
    local queryResult, err, errno, sqlstate = db:query(sql);
    if not queryResult or queryResult == nil then
        ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
        return false, nil, nil;
    end

    local govCountResList  = {};
    local govCountSizeList = {};
    -- 循环所有下级单位，因为有些单位可能没有统计数据，所以要以单位为基准进行统计
    for govIndex = 1, #govList do


        local govId   = tonumber(govList[govIndex][govIdFieldTab[govType]]);
        local govName = govList[govIndex][govNameFieldTab[govType]];

        local hasData = false;
        -- 循环所有统计结果
        for resIndex = 1, #queryResult do
            local record = queryResult[resIndex];
            if govId == tonumber(record["GOV_ID"]) then
                hasData = true;
                local valTab = _getResultRecord(record, govId, govName, countFields, 1);
                table.insert(govCountResList, valTab);
                valTab = _getResultRecord(record, govId, govName, sizeFields, 2);
                table.insert(govCountSizeList, valTab);
            end
        end

        if not hasData then
            local valTab = _getResultRecord(nil, govId, govName, countFields, 1);
            table.insert(govCountResList, valTab);
            valTab = _getResultRecord(nil, govId, govName, sizeFields, 2);
            table.insert(govCountSizeList, valTab);
        end
    end

    -- 封装标题行
    local subjectNameList = {};
    if govType == 1 then
        table.insert(subjectNameList, "市");
    elseif govType == 2 then
        table.insert(subjectNameList, "区（县）");
    elseif govType == 3 then
        table.insert(subjectNameList, "学校");
    elseif govType == 4 then
        table.insert(subjectNameList, "教师");
    end
    for index = 1, #keyMapList do
        local subjectName = keyMapList[index]["SUBJECT_NAME"];
        table.insert(subjectNameList, subjectName);
    end
    table.insert(subjectNameList, "合计");

    resultObj["attr_title"]    = subjectNameList;
    resultObj["arr_filecount"] = govCountResList;
    resultObj["arr_filesize"]  = govCountSizeList;

    return resultObj;
end

_AnalyseDataService.analyseDataByStage = analyseDataByStage;


----------------------------------------------------------------------------------
--[[
    私有函数：获取按学段统计省（或市、区）的sql语句
    作者：    申健           2015-04-19
    返回值1： SQL语句
]]
local function _getAnalyseGovPlatTotalSql(govType, unitId, destOrgId, stageId, startTime, endTime, strucId, hasChild, querySql)
    
    local subSql    = "";
    local groupSql  = "";
    if govType == 1 then
        subSql   = subSql .. " AND PROVINCE_ID=" .. unitId;
        querySql = querySql .. ",CITY_ID AS GOV_ID"
    elseif govType == 2 then
        subSql   = subSql .. " AND CITY_ID=" .. unitId;
        querySql = querySql .. ",DISTRICT_ID AS GOV_ID"
    elseif govType == 3 then
        subSql   = subSql .. " AND DISTRICT_ID=" .. unitId;
        querySql = querySql .. ",SCHOOL_ID AS GOV_ID"
    end

    local sql = "SELECT " .. querySql .. " FROM T_ANALYSE_GOV_PLAT WHERE 1=1 " .. subSql .." AND DEST_ORG_ID=" .. destOrgId .. " ";

    if stageId ~= nil and stageId ~= 0 then
        sql = sql .. " AND STAGE_ID=" .. stageId .. " ";
    end

    if startTime ~= nil and startTime ~= "" then
        sql = sql .. " AND DATE_TIME > '" .. startTime .. " 00:00:00' ";
    end
    if endTime ~= nil and endTime ~= "" then
        sql = sql .. " AND DATE_TIME < '" .. endTime .. " 23:59:59' ";
    end

    if strucId ~= nil then
        if hasChild == 0 then -- 0不包含子节点，1包含子节点
            sql = sql .. " AND STRUCTURE_ID=" .. strucId;
        else
            sql = sql .. " AND STRUCTURE_CODE LIKE '," .. strucId .. ",'";
        end
    end

    sql = sql .. groupSql.. " ORDER BY NULL;";

    return sql;
end

----------------------------------------------------------------------------------
--[[
	私有函数：获取按学段统计省（或市、区）的sql语句
	作者：    申健 	        2015-04-19
	返回值1： SQL语句
]]
local function _getAnalyseGovPlatSql(govType, unitId, destOrgId, stageId, startTime, endTime, strucId, hasChild, querySql)
    
    local subSql    = "";
    local groupSql  = "";
    if govType == 1 then
        subSql   = subSql .. " AND PROVINCE_ID=" .. unitId;
        querySql = querySql .. ",CITY_ID AS GOV_ID"
        groupSql = " GROUP BY CITY_ID"; 
    elseif govType == 2 then
        subSql   = subSql .. " AND CITY_ID=" .. unitId;
        querySql = querySql .. ",DISTRICT_ID AS GOV_ID"
        groupSql = " GROUP BY DISTRICT_ID"; 
    elseif govType == 3 then
        subSql   = subSql .. " AND DISTRICT_ID=" .. unitId;
        querySql = querySql .. ",SCHOOL_ID AS GOV_ID"
        groupSql = " GROUP BY SCHOOL_ID"; 
    end

    local sql = "SELECT " .. querySql .. " FROM T_ANALYSE_GOV_PLAT WHERE 1=1 " .. subSql .." AND DEST_ORG_ID=" .. destOrgId .. " ";

    if stageId ~= nil and stageId ~= 0 then
        sql = sql .. " AND STAGE_ID=" .. stageId .. " ";
    end

    if startTime ~= nil and startTime ~= "" then
        sql = sql .. " AND DATE_TIME > '" .. startTime .. " 00:00:00' ";
    end
    if endTime ~= nil and endTime ~= "" then
        sql = sql .. " AND DATE_TIME < '" .. endTime .. " 23:59:59' ";
    end

    if strucId ~= nil then
        if hasChild == 0 then -- 0不包含子节点，1包含子节点
            sql = sql .. " AND STRUCTURE_ID=" .. strucId;
        else
            sql = sql .. " AND STRUCTURE_CODE LIKE '%," .. strucId .. ",%'";
        end
    end

    sql = sql .. groupSql.. " ORDER BY NULL;";

    return sql;
end

----------------------------------------------------------------------------------
--[[
	私有函数：获取按学段统计学校下老师上传资源的sql语句
	作者：    申健 	        2015-04-19
	返回值1： SQL语句
]]
local function _getAnalysePersonPlatSql(schoolId, destOrgId, stageId, startTime, endTime, strucId, hasChild, querySql)
    
    local subSql   = " AND DEST_ORG_ID=" .. destOrgId .. " AND SCHOOL_ID=" .. schoolId;
    local groupSql = " GROUP BY PERSON_ID"; 
    querySql = querySql .. ",PERSON_ID AS GOV_ID"

    local sql = "SELECT " .. querySql .. " FROM T_ANALYSE_PERSON_PLAT WHERE 1=1 " .. subSql .. " "; 

    if stageId ~= nil and stageId ~= 0 then
        sql = sql .. " AND STAGE_ID=" .. stageId .. " ";
    end

    if startTime ~= nil then
        sql = sql .. " AND DATE_TIME > '" .. startTime .. " 00:00:00' ";
    end
    if endTime ~= nil then
        sql = sql .. " AND DATE_TIME < '" .. endTime .. " 23:59:59' ";
    end

    if strucId ~= nil then
        if hasChild == 0 then -- 0不包含子节点，1包含子节点
            sql = sql .. " AND STRUCTURE_ID=" .. strucId;
        else
            sql = sql .. " AND STRUCTURE_CODE LIKE '%," .. strucId .. ",%'";
        end
    end

    sql = sql .. groupSql.. " ORDER BY NULL;";

    return sql;
end

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-18
	参数1：   govType  	    行政单位类型：1省，2市，3区，4校
	参数2：   unitId  	    单位ID
    参数3：   platId  	    系统类型：1资源，2试卷，3试题，4备课，5微课
	参数4：   stageId  	    学段ID
	参数5：   subjectId  	科目ID
	参数6：   startTime  	开始时间
	参数7：   endTime  	    结束时间
	返回值1： boolean       true插入数据成功，false插入数据失败
]]
local function analyseDataByPlat(self, govType, unitId, destOrgId, stageId, startTime, endTime, strucId, hasChild, isAllSchool)

    local platKeyMap = {};

    local DBUtil 	= require "multi_check.model.DBUtil";
    local db 	 	= DBUtil: getDb();

    local resultObj = {};    
    local keyMapService      = require "management.analyse.services.AnalyseKeyMapService";
    local keyMapList, keyMap = keyMapService: getKeyMapOfPlats();
    local keyCount           = #keyMapList;

    local querySql, countFields, sizeFields = _getSubjectQueryFieldSql(keyMapList, keyMap);
    local cjson = require "cjson";
    ngx.log(ngx.ERR , "[sj_log]->[management_analyse]-> querySql ===> ", querySql);
    ngx.log(ngx.ERR , "[sj_log]->[management_analyse]-> countFields ===> ", cjson.encode(countFields));
    ngx.log(ngx.ERR , "[sj_log]->[management_analyse]-> sizeFields ===> ", cjson.encode(sizeFields));

    -- 获取统计的SQL语句
    local succFlag, govList, sql;
    local waitCheckFieldSql, waitCheckFieldList, waitResult;
    if govType == 4 then -- 学校
        succFlag, govList  = _getTeacherBySchool(unitId);
        sql = _getAnalysePersonPlatSql(unitId, destOrgId, stageId, startTime, endTime, strucId, hasChild, querySql);
    else
        succFlag, govList  = _getOrg(govType, unitId, stageId);
        sql = _getAnalyseGovPlatSql(govType, unitId, destOrgId, stageId, startTime, endTime, strucId, hasChild, querySql);
        
        -- 待审核记录条数统计
        waitCheckFieldSql, waitCheckFieldList = self: getWaitCountField(keyMapList, keyMap);
        ngx.log(ngx.ERR, "\n>>>>>>>>>> [sj_log]->[management_analyse]-> 统计待审核条数的sql语句：[", waitCheckFieldSql, "], waitCheckFieldList: [", encodeJson(waitCheckFieldList), "] <<<<<<<<<\n");
        waitResult = self: getWaitCheckCountResult(govType, unitId, destOrgId, stageId, strucId, hasChild, waitCheckFieldSql);
    end
    ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> 统计的sql语句 ===> [", sql, "] <===");

    -- 执行SQL语句，查询统计结果
    local queryResult, err, errno, sqlstate = db:query(sql);
    if not queryResult or queryResult == nil then
        ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
        return false, nil, nil;
    end

    local govCountResList  = {};
    local govCountSizeList = {};
    local govWaitCheckList = {};
    ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 是否获取所有学校 -> [[[", isAllSchool, "]]]");
    -- 循环所有下级单位，因为有些单位可能没有统计数据，所以要以单位为基准进行统计
    for govIndex = 1, #govList do

        local govId   = tonumber(govList[govIndex][govIdFieldTab[govType]]);
        local govName = govList[govIndex][govNameFieldTab[govType]];

        local hasData = false;
        -- 循环所有统计结果
        for resIndex = 1, #queryResult do
            local record = queryResult[resIndex];
            if govId == tonumber(record["GOV_ID"]) then
                hasData = true;
                local valTab = _getResultRecord(record, govId, govName, countFields, 1);
                table.insert(govCountResList, valTab);
                valTab = _getResultRecord(record, govId, govName, sizeFields, 2);
                table.insert(govCountSizeList, valTab);
            end
        end

        if not hasData and isAllSchool then
            local valTab = _getResultRecord(nil, govId, govName, countFields, 1);
            table.insert(govCountResList, valTab);
            valTab = _getResultRecord(nil, govId, govName, sizeFields, 2);
            table.insert(govCountSizeList, valTab);
        end

        if govType ~= 4 then
            -- 整理指定单位的待审核资源条数的统计数据
            if waitResult ~= nil then
                local hasWaitCheck = false;
                for resIndex = 1, #waitResult do
                    local record = waitResult[resIndex];
                    if govId == tonumber(record["UNIT_ID"]) then
                        hasWaitCheck = true;
                        local valTab = _getResultRecord(record, govId, govName, waitCheckFieldList, 1);
                        table.insert(govWaitCheckList, valTab);
                    end
                end
                if not hasWaitCheck then
                    local valTab = _getResultRecord(nil, govId, govName, waitCheckFieldList, 1);
                    table.insert(govWaitCheckList, valTab);
                end
            else
                local valTab = _getResultRecord(nil, govId, govName, waitCheckFieldList, 1);
                table.insert(govWaitCheckList, valTab);
            end
        end
    end

    -- 封装标题行
    local subjectNameList = {};
    if govType == 1 then
        table.insert(subjectNameList, "市");
    elseif govType == 2 then
        table.insert(subjectNameList, "区（县）");
    elseif govType == 3 then
        table.insert(subjectNameList, "学校");
    elseif govType == 4 then
        table.insert(subjectNameList, "教师");
    end
    for index = 1, #keyMapList do
        local subjectName = keyMapList[index]["PLAT_NAME"];
        table.insert(subjectNameList, subjectName);
    end
    table.insert(subjectNameList, "合计");

    resultObj["attr_title"]    = subjectNameList;
    resultObj["arr_filecount"] = govCountResList;
    resultObj["arr_filesize"]  = govCountSizeList;
    resultObj["arr_waitcheck"] = govWaitCheckList;
    if govType == 4 then -- 如果是显示学校下的教师，则不显示待审核资源的条数
        resultObj["show_wait_count"] = false;
    else
        resultObj["show_wait_count"] = true;
    end

    return resultObj;
end

_AnalyseDataService.analyseDataByPlat = analyseDataByPlat;
----------------------------------------------------------------------------------
--[[
    描述：    获取按章节目录统计资源大小和数量的sql语句
    作者：    申健           2015-05-15
    返回值1： SQL语句
]]
local function _getAnalyseByGovStrucSql(govType, unitId, destOrgId, startTime, endTime, strucId, hasChild, querySql)
    
    local subSql    = "";
    if govType == 1 then
        subSql   = subSql .. " AND PROVINCE_ID=" .. unitId;
    elseif govType == 2 then
        subSql   = subSql .. " AND CITY_ID=" .. unitId;
    elseif govType == 3 then
        subSql   = subSql .. " AND DISTRICT_ID=" .. unitId;
    end

    local sql = "SELECT " .. querySql .. " FROM T_ANALYSE_GOV_PLAT WHERE 1=1 " .. subSql .." AND DEST_ORG_ID=" .. destOrgId .. " ";

    if startTime ~= nil and startTime ~= "" then
        sql = sql .. " AND DATE_TIME > '" .. startTime .. " 00:00:00' ";
    end
    if endTime ~= nil and endTime ~= "" then
        sql = sql .. " AND DATE_TIME < '" .. endTime .. " 23:59:59' ";
    end

    if strucId ~= nil then
        if hasChild == 0 then -- 0不包含子节点，1包含子节点
            sql = sql .. " AND STRUCTURE_ID=" .. strucId;
        else
            sql = sql .. " AND STRUCTURE_CODE LIKE '%," .. strucId .. ",%'";
        end
    end

    return sql;
end
----------------------------------------------------------------------------------
--[[
    局部函数：按章节目录统计资源的总数量、总大小
    作者：    申健         2015-05-15
    参数1：   govType      行政单位类型：1省，2市，3区，4校
    参数2：   unitId       单位ID
    参数2：   destOrgId    共享目标单位的ID
    参数3：   strucId      结构的ID
    参数4：   hasChild     是否包含子节点：0不包含子节点，1包含子节点
    参数6：   startTime    开始时间
    参数7：   endTime      结束时间
    返回值1： table        统计结果
]]
local function analyseDataByStructure(self, govType, unitId, destOrgId, strucId, hasChild, startTime, endTime)

    local platKeyMap = {};
    local DBUtil    = require "common.DBUtil"; 

    local resultObj = {};    
    local keyMapService      = require "management.analyse.services.AnalyseKeyMapService";
    local keyMapList, keyMap = keyMapService: getKeyMapOfPlats();
    local keyCount           = #keyMapList;

    local querySql, countFields, sizeFields = _getSubjectQueryFieldSql(keyMapList, keyMap);
    local cjson = require "cjson";
    ngx.log(ngx.ERR , "[sj_log]->[management_analyse]-> querySql ===> ", querySql);
    ngx.log(ngx.ERR , "[sj_log]->[management_analyse]-> countFields ===> ", cjson.encode(countFields));
    ngx.log(ngx.ERR , "===> sizeFields ===> ", cjson.encode(sizeFields));

    -- 获取统计的SQL语句
    local sql = _getAnalyseByGovStrucSql(govType, unitId, destOrgId, startTime, endTime, strucId, hasChild, querySql);
    ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> 按学科统计的sql语句 ===> [", sql, "] <===");

    -- 执行SQL语句，查询统计结果
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return false;
    end
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> 按学科统计的sql执行的返回结果 ===> [", cjson.encode(queryResult), "] <===");
    local FileSizeM = require "common.FileSize";

    -- 获取待审核资源条数的统计结果
    local waitResult = self: getWaitCheckCountResult(govType, unitId, destOrgId, strucId, hasChild);

    local countObj = {};
    local sizeObj  = {};
    local titleObj = {};

    local totalCount = 0;
    local totalSize  = 0;
    for index = 1, #keyMapList do
        local keyObj   = keyMapList[index];
        local mapKey   = keyObj["MAP_KEY"];
        local keyTitle = keyObj["PLAT_NAME"];
        ngx.log(ngx.ERR, "[sj_log]->[management_analyse]-> key: [V" .. mapKey .. "_SIZE] ===> ", queryResult[1]["V" .. mapKey .. "_SIZE"]);
        local countVal = tonumber(queryResult[1]["V" .. mapKey .. "_COUNT"]);
        local sizeVal  = tonumber(queryResult[1]["V" .. mapKey .. "_SIZE"]);
        if sizeVal > 0 then
            sizeVal = FileSizeM: getFileSize(sizeVal, 1);
        else
            sizeVal = 0
        end
        totalCount  = totalCount + countVal;
        totalSize   = totalSize  + sizeVal;

        table.insert(titleObj , keyTitle);
        table.insert(sizeObj  , sizeVal);
        table.insert(countObj , countVal);
    end

    table.insert(titleObj , "合计");
    table.insert(sizeObj  , totalSize);
    table.insert(countObj , totalCount);

    resultObj["attr_title"]    = titleObj;
    resultObj["arr_filecount"] = countObj;
    resultObj["arr_filesize"]  = sizeObj;

    return resultObj;
end

_AnalyseDataService.analyseDataByStructure = analyseDataByStructure;

-- ----------------------------------------------------------------------------------
-- 函数描述： 从 checkInfo 中获取待审核条数统计所需要的数据
-- 日    期： 2015年9月8日
-- 参    数： checkInfo    table对象，存储审核信息记录的数据
-- 返 回 值： table对象，存储待审条数统计所需要的数据
-- ----------------------------------------------------------------------------------
local function getParamFromCheckInfo(self, checkInfo)
    local paramTable = {};
    paramTable["province_id"]    = checkInfo["PROVINCE_ID"];
    paramTable["city_id"]        = checkInfo["CITY_ID"];
    paramTable["district_id"]    = checkInfo["DISTRICT_ID"];
    paramTable["p_school_id"]    = checkInfo["P_SCHOOL_ID"];
    paramTable["c_school_id"]    = checkInfo["C_SCHOOL_ID"];
    paramTable["stage_id"]       = checkInfo["STAGE_ID"];
    paramTable["subject_id"]     = checkInfo["SUBJECT_ID"];
    paramTable["scheme_id"]      = checkInfo["SCHEME_ID"];
    paramTable["structure_id"]   = checkInfo["STRUCTURE_ID"];
    local strucCode = strucModel: getStrucCodeById(checkInfo["STRUCTURE_ID"]);
    paramTable["structure_code"] = "," .. string.gsub(strucCode, "_", ",") .. ",";
    paramTable["obj_type"]       = checkInfo["OBJ_TYPE"];

    return paramTable;
end
_AnalyseDataService.getParamFromCheckInfo = getParamFromCheckInfo;

-- ----------------------------------------------------------------------------------
-- 函数描述： 减少对应机构在指定节点下的待审核记录条数
-- 日    期： 2015年9月8日
-- 参    数： paramTable 存储参数数据的table对象
-- 返 回 值： sql语句
-- ----------------------------------------------------------------------------------
local function decreaseWaitCheckCount(self, paramTable)
    local mapKeyField = { 1, 3, 2, 4, 5 };
    paramTable["map_key"]      = mapKeyField[paramTable["obj_type"]];
    paramTable["oper_flag"]    = "decr";

    local AnalyseDataM  = require "management.analyse.model.AnalyseDataModel";
    local sql = AnalyseDataM: UpdateWaitCheck(paramTable);

    return sql;
end

_AnalyseDataService.decreaseWaitCheckCount = decreaseWaitCheckCount;

-- ----------------------------------------------------------------------------------
-- 函数描述： 增加对应机构在指定节点下的待审核记录条数
-- 日    期： 2015年9月8日
-- 参    数： paramTable 存储参数数据的table对象
-- 返 回 值： sql语句
-- ----------------------------------------------------------------------------------
local function increaseWaitCheckCount(self, paramTable)
    local mapKeyField = { 1, 3, 2, 4, 5 };
    paramTable["map_key"]      = mapKeyField[paramTable["obj_type"]];
    paramTable["oper_flag"]    = "incr";

    local AnalyseDataM  = require "management.analyse.model.AnalyseDataModel";
    local sql = AnalyseDataM: UpdateWaitCheck(paramTable);
    return sql;
end

_AnalyseDataService.increaseWaitCheckCount = increaseWaitCheckCount;

-- ----------------------------------------------------------------------------------
-- 函数描述： 获取待审核资源条数的统计字段
-- 日    期： 2015年9月9日
-- 参    数： name 缓存的name
-- 返 回 值： 如果有对应的缓存，则返回对应的值； 如果找不到对应的缓存，则返回false；
-- ----------------------------------------------------------------------------------
local function getWaitCountField(self, keyMapList, keyMap)

    local waitCountFieldList = {};
    local querySql  = " ";
    for index = 1, #keyMapList do
        local mapKey = keyMapList[index]["MAP_KEY"];
        querySql = querySql .. " ,IFNULL(SUM(V" .. mapKey .. "_WAIT_COUNT), 0) AS V" .. mapKey .. "_WAIT_COUNT ";
        table.insert(waitCountFieldList, "V" .. mapKey .. "_WAIT_COUNT");
    end

    return querySql, waitCountFieldList;
end
_AnalyseDataService.getWaitCountField = getWaitCountField;

-- ----------------------------------------------------------------------------------
-- 函数描述： 获取置顶机构下级单位的待审核资源的统计结果
-- 日    期： 2015年9月8日
-- 参    数： paramTable 存储参数数据的table对象
-- 返 回 值： sql语句
-- ----------------------------------------------------------------------------------
local function getWaitCheckCountResult(self, govType, unitId, destOrgId, stageId, strucId, hasChild, waitCheckFieldSql)

    local conditionSql = "";
    
    if stageId ~= nil and stageId ~= 0 then
        conditionSql = conditionSql .. " AND STAGE_ID=" .. stageId .. " ";
    end

    if strucId ~= nil then
        if hasChild == 0 then -- 0不包含子节点，1包含子节点
            conditionSql = conditionSql .. " AND STRUCTURE_ID=" .. strucId ;
        else
            conditionSql = conditionSql .. " AND STRUCTURE_CODE LIKE '%," .. strucId .. ",%' ";
        end
    end

    local sql = "SELECT UNIT_ID, UNIT_TYPE " .. waitCheckFieldSql ..
            " FROM T_ANALYSE_WAIT_CHECK " ..
            " WHERE DEST_ORG_ID = " .. destOrgId .. conditionSql .. 
            " AND UNIT_ID > 0 AND UNIT_TYPE = " .. (tonumber(govType) + 1) ..
            " GROUP BY UNIT_ID;";
    ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 统计待审核条数的sql语句：[", sql, "]");
    local queryResult, err = DBUtil: querySingleSql(sql);
    if not queryResult then
        error(err);
    end

    return queryResult;
end

_AnalyseDataService.getWaitCheckCountResult = getWaitCheckCountResult;
----------------------------------------------------------------------------------

return _AnalyseDataService;