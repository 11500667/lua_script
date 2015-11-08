--[[
    #申健   2015-04-18
    #描述： 资源统计的服务类
]]

local _AnalyseKeyMapService = {};

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-17
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function initSubjectKeyMap(self)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local db 	 	= DBUtil: getDb();
	local sqlTable = {};    
    local sql = "TRUNCATE TABLE T_ANALYSE_SUBJECT_KEY_MAP;";
    table.insert(sqlTable, sql);
    
	sql = "SELECT T1.STAGE_ID, T1.STAGE_NAME, T2.SUBJECT_ID, T2.SUBJECT_NAME "
     .. "FROM T_DM_STAGE T1 INNER JOIN T_DM_SUBJECT T2 ON T1.STAGE_ID = T2.STAGE_ID "
     .. "ORDER BY T1.STAGE_ID, T2.SUBJECT_ID ;";
	
	local queryResult, err, errno, sqlstate = db:query(sql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not queryResult or queryResult == nil or #queryResult == 0 then
		ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] ->  sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false, nil, nil;
	end
	
    local lastStageId = 0;
    local mapKey = 1;
	for index = 1, #queryResult do
        
        local insertSql = nil;
        local record    = queryResult[index];
        local stageId   = tonumber(record["STAGE_ID"]); 
        if stageId ~= lastStageId then
            mapKey = 1;
        end
        insertSql = "INSERT INTO T_ANALYSE_SUBJECT_KEY_MAP (STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME, MAP_KEY) VALUES (" .. record["STAGE_ID"] .. ",'" .. record["STAGE_NAME"] .. "'," .. record["SUBJECT_ID"] .. ",'" .. record["SUBJECT_NAME"] .. "'," .. mapKey .. ");";
        lastStageId = stageId;
        mapKey = mapKey + 1;
        table.insert(sqlTable, insertSql);
    end
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
    
    local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, 50);
    if boolResult then
        ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> >>>>>>>>>>>>>>> 初始化[科目]和预留字段的映射关系[成功] <<<<<<<<<<<<<<<<<<<<");
    else
        ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> >>>>>>>>>>>>>>> 初始化[科目]和预留字段的映射关系[失败] <<<<<<<<<<<<<<<<<<<<");
    end
end

_AnalyseKeyMapService.initSubjectKeyMap = initSubjectKeyMap;

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-17
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function initAppTypeKeyMap(self)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local db 	 	= DBUtil: getDb();
	local sqlTable = {};
    
    local sql = "TRUNCATE TABLE T_ANALYSE_APPTYPE_KEY_MAP;";
    table.insert(sqlTable, sql);
    
    -- 查询所有学科
	sql = "SELECT STAGE_ID, SUBJECT_ID FROM T_DM_SUBJECT ORDER BY STAGE_ID, SUBJECT_ID;";
	
	local queryResult, err, errno, sqlstate = db:query(sql);
	if not queryResult or queryResult == nil or #queryResult == 0 then
		ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false, nil, nil;
	end
	
    local appTypeModel = require "base.apptype.model.AppType";
    -- 循环学科
	for index = 1, #queryResult do
        
        local insertSql = nil;
        local record    = queryResult[index];
        -- 获取学科下的应用类型
        ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 查询科目[", record["SUBJECT_ID"] .."]下的应用类型 <===");
        local succFlag, appTypeList = appTypeModel: getBySubject(record["SUBJECT_ID"]);
        if succFlag and appTypeList ~= nil and #appTypeList > 0 then
            for appTypeIndex = 1, #appTypeList do
                
                local appTypeRecord = appTypeList[appTypeIndex];
                
                insertSql = "INSERT INTO T_ANALYSE_APPTYPE_KEY_MAP (" .. 
                "STAGE_ID, SUBJECT_ID, APP_TYPE_ID, APP_TYPE_NAME, MAP_KEY) " ..
                "VALUES (" .. record["STAGE_ID"] .. ",'" .. record["SUBJECT_ID"] .. "'," 
                .. appTypeRecord["app_type_id"] .. ",'" .. appTypeRecord["app_type_name"] .. "'," 
                .. appTypeIndex .. ");";
                
                table.insert(sqlTable, insertSql);
            end
        end
        
    end
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
    
    local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, 50);
    if boolResult then
        ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> >>>>>>>>>>>>>>> 初始化[应用类型]和预留字段的映射关系[成功] <<<<<<<<<<<<<<<<<<<<");
    else
        ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> >>>>>>>>>>>>>>> 初始化[应用类型]和预留字段的映射关系[失败] <<<<<<<<<<<<<<<<<<<<");
    end
end

_AnalyseKeyMapService.initAppTypeKeyMap = initAppTypeKeyMap;

----------------------------------------------------------------------------------
--[[
	局部函数：获取指定学段下的科目与预留字段的映射关系
	作者：    申健 	        2015-04-18
	参数1：   stageId  	    学段ID
	返回值1： SQL语句
]]
local function getKeyMapByStage(self, stageId)
	local keyMapModel   = require "management.analyse.model.AnalyseKeyMap";
    local subjectKeyMap = keyMapModel: getKeyMapByStage(stageId);
    
    local keyMap        = {};
    for index = 1, #subjectKeyMap do
        local record = subjectKeyMap[index];
        keyMap[record.MAP_KEY] = record.SUBJECT_NAME;
    end
    return subjectKeyMap, keyMap;
end

_AnalyseKeyMapService.getKeyMapByStage = getKeyMapByStage;

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-18
	参数1：   subjectId  	科目ID
	返回值1： SQL语句
]]
local function getKeyBySubject(self, subjectId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local db 	 	= DBUtil: getDb();
	-- 查询所有学科
	local sql = "SELECT MAP_KEY FROM T_ANALYSE_SUBJECT_KEY_MAP WHERE SUBJECT_ID=" .. subjectId .. ";";
	
	local queryResult, err, errno, sqlstate = db:query(sql);
	if not queryResult or queryResult == nil or #queryResult == 0 then
		ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false, nil, nil;
	end
	
    local mapKey = queryResult[1]["MAP_KEY"];
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
    
    return mapKey;
end

_AnalyseKeyMapService.getKeyBySubject = getKeyBySubject;

----------------------------------------------------------------------------------
local _platKeyList = {
	{ PLAT_ID = 1, MAP_KEY = 1, PLAT_NAME="资源"},
	{ PLAT_ID = 2, MAP_KEY = 2, PLAT_NAME="试卷"},
	{ PLAT_ID = 3, MAP_KEY = 3, PLAT_NAME="试题"},
	{ PLAT_ID = 4, MAP_KEY = 4, PLAT_NAME="备课"},
	{ PLAT_ID = 5, MAP_KEY = 5, PLAT_NAME="微课"}
}

local _platKeyMap = {};
_platKeyMap[1] = "资源";
_platKeyMap[2] = "试卷";
_platKeyMap[3] = "试题";
_platKeyMap[4] = "备课";
_platKeyMap[5] = "微课";


----------------------------------------------------------------------------------
--[[
	局部函数：获取指定学段下的科目与预留字段的映射关系
	作者：    申健 	        2015-04-18
	参数1：   stageId  	    学段ID
	返回值1： SQL语句
]]
local function getKeyMapOfPlats(self)
    return _platKeyList, _platKeyMap;
end

_AnalyseKeyMapService.getKeyMapOfPlats = getKeyMapOfPlats;

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-18
	参数1：   subjectId  	科目ID
	返回值1： SQL语句
]]
local function getKeyByPlat(self, platId)
	return platId;
end

_AnalyseKeyMapService.getKeyByPlat = getKeyByPlat;
----------------------------------------------------------------------------------

return _AnalyseKeyMapService;