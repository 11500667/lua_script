--[[
#申健 2015-03-12
#描述：审核信息的基础函数类
]]
local _CheckInfo = { author="shenjian"};

---------------------------------------------------------------------------
--[[
	局部函数：根据ID获取审核记录
	作者： 	  申健 		2015-03-08
	参数： 	  checkId  	审核记录的ID
	返回值1： boolean 	查询是否成功
	返回值2： 审核记录的table
]]
local function getById(self, checkId)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	local sql = "SELECT ID, OBJ_TYPE, OBJ_ID_INT, OBJ_ID_CHAR, STAGE_ID, SUBJECT_ID, SCHEME_ID, STRUCTURE_ID, SHARE_PERSON_ID, SHARE_PERSON_NAME, PROVINCE_ID, CITY_ID, DISTRICT_ID, P_SCHOOL_ID, C_SCHOOL_ID, CHECK_PATH, CREATE_TIME, IS_REPORTED, REPORT_UNIT, HOLD_FLAG, CHECK_WAY, FORCE_CHECK  FROM T_BASE_CHECK_INFO WHERE ID=" .. checkId;
	local result, err, errno, sqlstate = db: query(sql);
	if not result or #result==0 then 
		return false, nil;
	end
	
	return true, result[1];
end

_CheckInfo.getById = getById;

---------------------------------------------------------------------------
--[[
	局部函数：更新审核记录的CHECK_PATH
	作者：    申健 	        2015-03-14
	参数1：   checkId  		审核记录的ID
	参数2：   checkPath  	审核记录的审核路径
	返回值1： boolean 		更新是否成功
]]
local function updateCheckPath(self, checkId, checkPath)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 更新CHECK_ID 为[" .. checkId .. "]的审核记录的审核路径为[" .. checkPath .. "] <=== ");
	local sql = "UPDATE T_BASE_CHECK_INFO SET CHECK_PATH='" .. checkPath .. "' WHERE ID=" .. checkId .. ";";
	local result, err, errno, sqlstate = db: query(sql);
	if not result then 
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 更新CHECK_PATH出错：错误信息[" .. err .. "] <=== ");
		return false;
	end
	
	return true;
end

_CheckInfo.updateCheckPath = updateCheckPath;

---------------------------------------------------------------------------
--[[
	局部函数：获取更新审核记录的CHECK_PATH的SQL语句
	作者：    申健 	        2015-03-14
	参数1：   checkId  		审核记录的ID
	参数2：   checkPath  	审核记录的审核路径
	返回值1： SQL语句
]]
local function getUpdateCheckPathSql(self, checkId, checkPath)
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 更新CHECK_ID 为[" .. checkId .. "]的审核记录的审核路径为[" .. checkPath .. "] <=== ");
	local sql = "UPDATE T_BASE_CHECK_INFO SET CHECK_PATH='" .. checkPath .. "' WHERE ID=" .. checkId .. ";";
	return sql;
end

_CheckInfo.getUpdateCheckPathSql = getUpdateCheckPathSql;

---------------------------------------------------------------------------
--[[
	局部函数：获取更新审核记录的CHECK_PATH的SQL语句
	作者：    申健 	        2015-03-14
	参数1：   checkId  		审核记录的ID
	参数2：   checkPath  	审核记录的审核路径
	返回值1： SQL语句
]]
local function getDeleteObjSql(self, objType, objIdInt, objIdChar, strucId, unitId)
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> getDeleteObjSql ===> 参数：objType: [", objType, "], objIdInt: [", objIdInt, "], objIdChar: [", objIdChar, "], strucId: [", strucId, "], unitId: [", unitId, "]<=== ");
	
	local sql = "";
	if tonumber(objType) == 1 then -- 资源
		return self.updateResReleaseStatus(self, objIdInt, unitId);
	elseif tonumber(objType) == 2 then -- 试题
        local   quesInfoModel  = require "question.model.QuestionInfo";
        return  quesInfoModel: updateDeleteStatus(objIdChar, strucId, unitId);
	elseif tonumber(objType) == 3 then -- 试卷
		local 	paperInfoModel = require "paper.model.PaperInfoModel";
		return 	paperInfoModel: updateDeleteStatus(objIdInt, unitId);
	elseif tonumber(objType) == 4 then -- 备课
		return self.updateResReleaseStatus(self, objIdInt, unitId);
	elseif tonumber(objType) == 5 then -- 微课
		local 	wkdsModel = require "wkds.model.WkdsModel";
		return 	wkdsModel: updateDeleteStatus(objIdInt, unitId);
	end
	return sql;
end

_CheckInfo.getDeleteObjSql = getDeleteObjSql;

---------------------------------------------------------------------------
--[[
	局部函数：获取更新资源RELEASE_STATUS为4的SQL语句和缓存对象
	作者：    申健 	        2015-03-14
	参数1：   checkId  		审核记录的ID
	参数2：   checkPath  	审核记录的审核路径
	返回值1： SQL语句
]]
local function updateResReleaseStatus(self, resIdInt, groupId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local myTs 	 	= require "resty.TS"
	local db 	 	= DBUtil: getDb();
	local currentTS = myTs.getTs();
	
	local sql = "UPDATE T_RESOURCE_INFO SET RELEASE_STATUS=4, UPDATE_TS= ".. currentTS .. " WHERE RESOURCE_ID_INT=" .. resIdInt .. " AND GROUP_ID=" .. groupId .. ";";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,"..resIdInt..";filter=group_id," .. groupId .. ";filter=release_status,1,3;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 获取审核记录失败");
		return false, nil, nil;
	end
	
	local resInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
    local cacheKey = "resource_" .. resInfoId;
	return true, sql, { obj_type=1, key=cacheKey, field_name="release_status", field_value="4" };

end

_CheckInfo.updateResReleaseStatus = updateResReleaseStatus;

---------------------------------------------------------------------------

--[[
	局部函数：获取更新审核记录的CHECK_PATH的SQL语句
	作者：    申健 	        2015-03-14
	参数1：   checkId  		审核记录的ID
	参数2：   checkPath  	审核记录的审核路径
	返回值1： SQL语句
]]
local function getDelCheckInfoSql(self, checkId)
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> delCheckInfo ===> 参数：checkId: [", checkId, "]<=== ");
	local sql = "DELETE FROM T_BASE_CHECK_INFO WHERE ID=" .. checkId .. ";";
	return sql;
end

_CheckInfo.getDelCheckInfoSql = getDelCheckInfoSql;

---------------------------------------------------------------------------------------
--[[
	函数描述：删除审核记录
	参数：unitId 	 	单位ID
	参数：checkId 		审核记录的ID
	参数：checkStatus 	修改后的审核状态
	参数：checkMsg		审核信息
]]
local function getDelSqlAndCache(self, checkId)
    
    local fieldTab = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "P_SCHOOL_ID", "C_SCHOOL_ID"};
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 要删除的审核信息的ID ===> [" .. checkId .. "] ");
    local succFlag, checkInfo = self: getById(checkId);
    
    local cjson = require "cjson";
    
    -- 删除审核记录
    local sqlTable 	      = {};
    local delCacheTable   = {};
    
    -- 删除对象已经共享的记录；
    local objIdInt   = checkInfo.OBJ_ID_INT;
    local objIdChar  = checkInfo.OBJ_ID_CHAR;
    local strucId    = checkInfo.STRUCTURE_ID;
    local objType    = checkInfo.OBJ_TYPE;
    local personId   = checkInfo.SHARE_PERSON_ID;
    
    local CheckPath  = require "multi_check.model.CheckPath";
    local pathBean   = CheckPath: new_withoutLevel(checkInfo.CHECK_PATH);
    
    local groupIdTab = {};
    local destUnitLevel, currUnitLevel, tempStatus = pathBean: getDestUnit();
    for unitLevel=destUnitLevel, 5 do
        table.insert(groupIdTab, tonumber(checkInfo[fieldTab[unitLevel]]));
    end
    
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> groupIdTab值输出 ===> ", cjson.encode(groupIdTab));
    local succFlag = true;
    if objType == 1 or objType == 4 then --1:资源, 4:备课
        local resInfoModel = require "resource.model.ResourceInfo";
        succFlag, sqlTable, delCacheTable = resInfoModel: getDelSqlAndCache(objIdInt, groupIdTab);
    elseif objType == 2 then -- 试题
        local quesInfoModel = require "question.model.QuestionInfo";
        succFlag, sqlTable, delCacheTable = quesInfoModel: getDelSqlAndCache(objIdChar, strucId, groupIdTab);
    elseif objType == 3 then -- 试卷
        local paperInfoModel = require "paper.model.PaperInfoModel";
        succFlag, sqlTable, delCacheTable = paperInfoModel: getDelSqlAndCache(objIdInt, groupIdTab);
    elseif objType == 4 then -- 备课
    
    elseif objType == 5 then -- 微课
        local wkdsInfoModel = require "wkds.model.WkdsModel";
        succFlag, sqlTable, delCacheTable = wkdsInfoModel: getDelSqlAndCache(objIdInt, groupIdTab);
    end
    
    -- 删除T_BASE_CHECK_INFO表对象的SQL语句
    local delCheckInfoSql = self: getDelCheckInfoSql(checkId);
    table.insert(sqlTable, delCheckInfoSql);
    
    -- 删除共享统计的数据
    local AnalyseService  = require "management.analyse.services.AnalyseDataService";
	local analyseSqlTable = AnalyseService: getDelPlatAnalyseSql(objIdInt, objIdChar, objType, strucId, personId, 5, groupIdTab);
    if analyseSqlTable ~= nil and #analyseSqlTable ~= 0 then
        for index = 1, #analyseSqlTable do
            local delAnalyseSql = analyseSqlTable[index];
            table.insert(sqlTable, delAnalyseSql);
        end
    end

    -- 更新共享统计中待审核记录条数的数据
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> \ntempStatus 的值： [", tempStatus, "], \n 类型：[", type(tempStatus), "]\n");
    if tempStatus == "10" or tempStatus == "13" then
        local paramTable = AnalyseService: getParamFromCheckInfo(checkInfo);
        paramTable["dest_org_id"] = checkInfo[fieldTab[destUnitLevel]];
        paramTable["unit_id"]     = checkInfo[fieldTab[currUnitLevel]];
        paramTable["unit_type"]   = currUnitLevel;
        local updateWaitCheckSql = AnalyseService: decreaseWaitCheckCount(paramTable);
        table.insert(sqlTable, updateWaitCheckSql);
    end

    -- 删除推荐的记录
    checkInfo["GROUP_IDS"]  = groupIdTab;
    local RecommendModel = require "multi_check.model.Recommend";
    RecommendModel: delRecommendData(checkInfo);

    return sqlTable, delCacheTable;
end

_CheckInfo.getDelSqlAndCache = getDelSqlAndCache;

---------------------------------------------------------------------------
--[[
	局部函数：批量向Redis缓存中插入资源缓存
	参数：cacheTable 	 记录资源缓存对象的table
]]
local function batchUpdateObjDeleteStatus2Redis(self, cacheTable)
    local ssdbUtil  = require "multi_check.model.SSDBUtil";
    local CacheUtil = require "multi_check.model.CacheUtil";
    local cache = CacheUtil: getRedisConn();


	if cacheTable~=nil and #cacheTable > 0 then
		for i=1, #cacheTable do
            local cacheInfo = cacheTable[i];
			local objType   = tonumber(cacheInfo["obj_type"]);
			local keyName 	= cacheInfo["key"];
            local fieldName = cacheInfo["field_name"];
			local fieldVal	= cacheInfo["field_value"];
            if objType == 1 or objType == 4 then -- 资源、备课
                ssdbUtil:hset(keyName, fieldName, fieldVal);
            else
                cache:hmset(keyName, fieldName, fieldVal);
            end
            

   --          if objType == 1 or objType == 4 then -- 资源
   --              cache:hmset(
   --                  keyName, 
   --                  fieldName,  fieldVal 
   --              );
   --          elseif objType==2 then -- 试题
   --              cache:hmset(
   --                  keyName, 
   --                  fieldName,  fieldVal 
   --              );
			-- elseif objType==3 then -- 试卷
			-- 	cache:hmset(
   --                  keyName, 
   --                  fieldName,  fieldVal 
   --              );
			-- elseif objType==4 then -- 备课
			
			-- elseif objType==5 then -- 微课
			-- 	cache:hmset(
   --                  keyName, 
   --                  fieldName,  fieldVal 
   --              );
			-- end
		end
	end
	
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
end

_CheckInfo.batchUpdateObjDeleteStatus2Redis = batchUpdateObjDeleteStatus2Redis;

---------------------------------------------------------------------------------------
--[[
	函数描述： 删除单个审核记录
    日期：     shenjian 2015-04-09
	参数：     checkId 	 	审核记录的ID
    返回值：   true 删除成功，false删除失败
]]
local function delCheckInfo(self, checkId)
    
    local sqlTable, delCacheTable = self: getDelSqlAndCache(checkId);
    local result = _batchInsert2DB(sqlTable, 50);
    self: batchUpdateObjDeleteStatus2Redis(delCacheTable);
    
    if not result then 
        return false;
    end
    
    return true;
end

_CheckInfo.delCheckInfo = delCheckInfo;
---------------------------------------------------------------------------------------
--[[
	函数描述： 批量删除审核记录
    日期：     shenjian     2015-04-09
	参数：     checkIds 	table对象，存储
    返回值：   true 删除成功，false删除失败
]]
local function batchDelCheckInfo(self, checkIds)
    
    local sqlTable 	      = {};
    local delCacheTable   = {};
    
    local idsCount = #checkIds;
    if idsCount == 0 then
        return false;
    else
        
        for index=1, idsCount do
            
            local checkId = checkIds[index];
            local tempSqlTable, tempDelCacheTable = self: getDelSqlAndCache(checkId);
            
            if #tempSqlTable > 0 then
                for tempIndex=1, #tempSqlTable do
                    table.insert(sqlTable, tempSqlTable[tempIndex]);
                end
            end
            if #tempDelCacheTable > 0 then
                for tempIndex=1, #tempDelCacheTable do
                    table.insert(delCacheTable, tempDelCacheTable[tempIndex]);
                end
            end
        end
        
    end
    
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> delCacheTable:[", cjson.encode(delCacheTable) , "]");

    local DBUtilModel = require "multi_check.model.DBUtil";    
    local result = DBUtilModel: batchExecuteSqlInTx(sqlTable, 50);
    self: batchUpdateObjDeleteStatus2Redis(delCacheTable);
    
    if not result then 
        return false;
    end
    
    return true;
end

_CheckInfo.batchDelCheckInfo = batchDelCheckInfo;
---------------------------------------------------------------------------
--[[
    描述：     删除单个审核记录
    日期：     shenjian       2015-04-09
    参数：     checkId        审核记录的ID
    返回值：   true 删除成功，false删除失败
]]
local function getCheckPath(self, objType, objIdInt)
    
    local sql = "SELECT CHECK_PATH FROM T_BASE_CHECK_INFO WHERE OBJ_TYPE=" .. objType .. " AND OBJ_ID_INT=" .. objIdInt .. " ORDER BY CREATE_TIME DESC LIMIT 1;" ;

    local DBUtil = require "common.DBUtil";

    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult or #queryResult == 0 then
        return nil;
    end
    local checkPath = queryResult[1]["CHECK_PATH"];
    local checkPathModel  = require "multi_check.model.CheckPath";
    local pathBean = checkPathModel: new_withoutLevel(checkPath);

    return pathBean;
end

_CheckInfo.getCheckPath = getCheckPath;
---------------------------------------------------------------------------
--[[
    描述：     根据OBJ_ID_INT获取审核状态
    日期：     shenjian       2015-04-09
    参数：     objType        对象类型
    参数：     objIdIntTable  审核记录的ID
    返回值：   true 删除成功，false删除失败
]]
local function getCheckStatusByObjIdInt(self, objType, objIdTable)
    
    local segmentCondition = " OBJ_ID_INT IN ("
    for i = 1, #objIdTable do
        if i == 1 then
            segmentCondition =  segmentCondition .. tonumber(objIdTable[i]);
        else
            segmentCondition =  segmentCondition .. "," .. tonumber(objIdTable[i]);
        end
    end
    segmentCondition =  segmentCondition .. ")";

    local querySql = "SELECT OBJ_ID_INT, OBJ_TYPE, CHECK_PATH FROM T_BASE_CHECK_INFO WHERE OBJ_TYPE=" .. objType .. " AND " .. segmentCondition .. " ORDER BY CREATE_TIME DESC" ;
    
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]->查询审核状态的sql：[[[", querySql, "]]]");

    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult or #queryResult == 0 then
        return nil;
    end
    
    local checkPathModel = require "multi_check.model.CheckPath";
    local statusMap = {};
    for index = 1 , #queryResult do
        local record    = queryResult[index];
        local objIdInt  = tostring(record["OBJ_ID_INT"]);
        local checkPath = record["CHECK_PATH"];
        local pathBean  = checkPathModel: new_withoutLevel(checkPath);
        local nowStatus = pathBean:getNowCheckLevelAndState();
        
        if statusMap[objIdInt] == nil or statusMap[objIdInt] == ngx.null then
            statusMap[objIdInt] = nowStatus;
        end
    end
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> statusMap:[", cjson.encode(statusMap), "]");
    return statusMap;
end

_CheckInfo.getCheckStatusByObjIdInt = getCheckStatusByObjIdInt;
---------------------------------------------------------------------------
--[[
    描述：     根据OBJ_ID_INT获取审核状态
    日期：     shenjian       2015-04-09
    参数：     objType        对象类型
    参数：     objIdIntTable  审核记录的ID
    返回值：   true 删除成功，false删除失败
]]
local function getCheckStatusByObjIdChar(self, objType, objIdTable)
    
    local segmentCondition = " OBJ_ID_CHAR IN ("
    for i = 1, #objIdTable do
        if i == 1 then
            segmentCondition =  segmentCondition .. ngx.quote_sql_str(objIdTable[i]);
        else
            segmentCondition =  segmentCondition .. "," .. ngx.quote_sql_str(objIdTable[i]);
        end
    end
    segmentCondition =  segmentCondition .. ")";

    local querySql = "SELECT OBJ_ID_CHAR, OBJ_TYPE, CHECK_PATH FROM T_BASE_CHECK_INFO WHERE OBJ_TYPE=" .. objType .. " AND " .. segmentCondition .. " ORDER BY CREATE_TIME DESC;" ;
    
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]->查询审核状态的sql：[[[", querySql, "]]]");

    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult or #queryResult == 0 then
        return nil;
    end
    
    local checkPathModel = require "multi_check.model.CheckPath";
    local statusMap = {};
    
    for index = 1 , #queryResult do
        local record    = queryResult[index];
        local objIdChar = record["OBJ_ID_CHAR"];
        local checkPath = record["CHECK_PATH"];
        local pathBean  = checkPathModel: new_withoutLevel(checkPath);
        local nowStatus = pathBean:getNowCheckLevelAndState();

        if statusMap[objIdChar] == nil or statusMap[objIdChar] == ngx.null then
            statusMap[objIdChar] = nowStatus;
        end
    end
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> statusMap:[", cjson.encode(statusMap), "]");
    return statusMap;
end

_CheckInfo.getCheckStatusByObjIdChar = getCheckStatusByObjIdChar;
---------------------------------------------------------------------------------------

return _CheckInfo;