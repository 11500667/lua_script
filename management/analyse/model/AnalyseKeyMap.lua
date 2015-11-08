--[[
    #申健   2015-04-17
    #描述： 审核信息的基础函数类
]]

local _AnalyseKeyMap = {};

----------------------------------------------------------------------------------
--[[
	局部函数：初始化科目和预留字段之间的映射关系
	作者：    申健 	        2015-04-17
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function getKeyMapBySubject(self, subjectId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local db 	 	= DBUtil: getDb();
	
	local sql = "SELECT STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME, MAP_KEY "
             .. "FROM T_ANALYSE_SUBJECT_KEY_MAP WHERE SUBJECT_ID = " .. subjectId;
	
	local queryResult, err, errno, sqlstate = db:query(sql);
	if not queryResult or queryResult == nil or #queryResult == 0 then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false, nil, nil;
	end
	
    local sqlTable = {};
	for index = 1, #queryResult do
        
        local insertSql = nil;
        local record    = queryResult[index];
        
        insertSql = "INSERT INTO T_ANALYSE_SUBJECT_KEY_MAP (STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME, MAP_KEY) VALUES (" .. record["STAGE_ID"] .. ",'" .. record["STAGE_NAME"] .. "'," .. record["SUBJECT_ID"] .. ",'" .. record["SUBJECT_NAME"] .. "'," .. index .. ");";
        
        table.insert(sqlTable, insertSql);
    end
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
    
    local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, 50);
    if boolResult then
        ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 初始化[科目]和预留字段的映射关系[成功] <<<<<<<<<<<<<<<<<<<<");
    else
        ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 初始化[科目]和预留字段的映射关系[失败] <<<<<<<<<<<<<<<<<<<<");
    end
end

_AnalyseKeyMap.initSubjectKeyMap = initSubjectKeyMap;

----------------------------------------------------------------------------------
--[[
	局部函数：获取指定学段下的科目与预留字段的映射关系
	作者：    申健 	        2015-04-17
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function getKeyMapByStage(self, stageId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local db 	 	= DBUtil: getDb();
	
	local sql = "SELECT STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME, MAP_KEY "
             .. "FROM T_ANALYSE_SUBJECT_KEY_MAP WHERE STAGE_ID = " .. stageId 
             .. " ORDER BY MAP_KEY ASC";
	
	local queryResult, err, errno, sqlstate = db:query(sql);
	if not queryResult or queryResult == nil or #queryResult == 0 then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false, nil, nil;
	end
	
    local recordTable = {};
	for index = 1, #queryResult do
        local record = queryResult[index];      
        table.insert(recordTable, record);
    end
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
    return recordTable;
end

_AnalyseKeyMap.getKeyMapByStage = getKeyMapByStage;

----------------------------------------------------------------------------------

return _AnalyseKeyMap;