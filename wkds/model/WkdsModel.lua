--[[
#申健 2015-03-31
#描述：微课的基础类接口
]]

local _WkdsInfoModel = {};

---------------------------------------------------------------------------
--[[
	局部函数：获取新的 T_WKDS_INFO 表的主键ID（从SSDB中获取）
	作者： 申健 2015-03-31
	返回值：number类型，新的微课记录的ID
]]
local function getNewRecordPK(self)
	-- 获取redis连接
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	-- 获取 T_WKDS_INFO 表的新的主键
	local newPK = cache:incr("t_wkds_info_pk");
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
	return newPK;
end

_WkdsInfoModel.getNewRecordPK = getNewRecordPK;

--[[
	局部函数：判断微课记录是否已经共享给指定的单位，用于判断是否需要插入该机构的记录
	参数：	wkdsIdInt	微课的记录的WKDS_ID_INT
	参数：	groupId		指定单位的ID
]]
local function isWkdsInfoExist(self, wkdsIdInt, groupId)
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	sql = "SELECT SQL_NO_CACHE COUNT(ID) AS ROW_COUNT FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=WKDS_ID_INT," .. wkdsIdInt .. ";filter=GROUP_ID," .. groupId .. ";filter=TYPE,1;filter=B_DELETE,0;' LIMIT 1;";
	dbResult, err, errno, sqlstate = db:query(sql);
	if not dbResult then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false;
	end
	
	if #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取wkdsIdInt->[", wkdsIdInt, "]的微课记录，记录是否存在:[否]");
		return false;
	end;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	if tonumber(dbResult[1]["ROW_COUNT"]) > 0 then
		return true;
	else
		return false;
	end
end

_WkdsInfoModel.isWkdsInfoExist = isWkdsInfoExist;

---------------------------------------------------------------------------
--[[
	局部函数：根据WKDS_ID_INT 获取在T_WKDS_INFO表中的ID
]]
local function getWkdsInfoId(self, objIdInt)
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	sql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=WKDS_ID_INT,"..objIdInt..";filter=TYPE,1;filter=GROUP_ID,2;' LIMIT 1;";
	dbResult, err, errno, sqlstate = db:query(sql);
	if not dbResult then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false;
	end
	
	if #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取wkdsIdInt->[", wkdsIdInt, "]的微课记录，记录是否存在:[否]");
		return false;
	end;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return dbResult[1].ID;

end

_WkdsInfoModel.getWkdsInfoId = getWkdsInfoId;

---------------------------------------------------------------------------
--[[
	局部函数：获取审核通过后需要向 T_WKDS_INFO 表插入记录的sql语句和缓存对象
	参数：	p_wkdsIdInt   原始记录的在 T_WKDS_INFO 表的ID
	参数：	p_unitId   	  审核人所在单位的ID
	参数：	p_objType  	  待审核对象的类型：1资源，2试题，3试卷，4备课，5微课
]]

local function getWkdsInfoInsertSqlAndCache(self, p_wkdsIdInt, p_unitId, p_objType)
	
	local wkdsInfoId = self: getWkdsInfoId(p_wkdsIdInt);
	
	local p_myTs = require "resty.TS"
	local p_currentTS = p_myTs.getTs();
	local newWkdsInfoId = self:getNewRecordPK();
	-- 判断微课是否已经存在
	local isExist = self: isWkdsInfoExist(p_wkdsIdInt, p_unitId);
	
	if not isExist then
	
		local sql = "INSERT INTO T_WKDS_INFO (ID, WKDS_ID_INT, WKDS_ID_CHAR, GROUP_ID, WKDS_NAME, TEACHER_NAME, TEACHER_NAME_PY, TEACHER_INTRO, PERSON_ID, IDENTITY_ID, CREATE_TIME, STUDY_INSTR, DESIGN_INSTR, PRACTICE_INSTR, DOWNLOADABLE, CONTENT_JSON, TS, UPDATE_TS, SCHEME_ID, SCHEME_ID_CHAR, STRUCTURE_ID, STRUCTURE_ID_CHAR, PLAY_COUNT, DOWNLOAD_COUNT, SCORE_COUNT, SCORE_TOTAL, SCORE_AVERAGE, ISDRAFT, SUBJECT_ID, TYPE, TYPE_ID, TABLE_PK, CHECK_STATUS, CHECK_MESSAGE, WK_TYPE, WK_TYPE_NAME, B_DELETE, UPLOADER_ID, STAGE_ID, W_TYPE) SELECT " .. newWkdsInfoId .. ", WKDS_ID_INT, WKDS_ID_CHAR, " .. p_unitId .. ", WKDS_NAME, TEACHER_NAME, TEACHER_NAME_PY, TEACHER_INTRO, PERSON_ID, IDENTITY_ID, CREATE_TIME, STUDY_INSTR, DESIGN_INSTR, PRACTICE_INSTR, DOWNLOADABLE, CONTENT_JSON, " .. p_currentTS .. ", " .. p_currentTS .. ", SCHEME_ID, SCHEME_ID_CHAR, STRUCTURE_ID, STRUCTURE_ID_CHAR, PLAY_COUNT, DOWNLOAD_COUNT, SCORE_COUNT, SCORE_TOTAL, SCORE_AVERAGE, ISDRAFT, SUBJECT_ID, TYPE, TYPE_ID, TABLE_PK, 0, '无', WK_TYPE, WK_TYPE_NAME, 0 , UPLOADER_ID, STAGE_ID, W_TYPE FROM t_wkds_info WHERE ID=" .. wkdsInfoId .. ";";
		
		local CacheUtil = require "multi_check.model.CacheUtil";
		local cache = CacheUtil: getRedisConn();
		
		local wkdsInfoCache = cache:hmget(
				"wkds_" .. wkdsInfoId, 
				"wkds_id_int", "wkds_id_char", "group_id", "wkds_name", "teacher_name", "teacher_name_py", "teacher_intro", "person_id", "identity_id", "create_time", "study_instr", "design_instr", "practice_instr", "downloadable", "content_json", "ts", "scheme_id", "structure_id", "scheme_id_char", "structure_id_char", "play_count", "download_count", "score_count", "score_total", "score_average", "isdraft", "subject_id", "type", "type_id", "table_pk", "check_status", "check_message", "wk_type", "wk_type_name", "b_delete", "uploader_id", "stage_id", "w_type"
			);
		
		wkdsInfoCache[3]  = tostring(p_unitId); 	-- group_id
		wkdsInfoCache[16] = tostring(p_currentTS); 	-- ts
		wkdsInfoCache[31] = "0"; 					-- check_status
		wkdsInfoCache[32] = "无"; 					-- check_message
		-- 将Redis连接归还连接池
		CacheUtil:keepConnAlive(cache);
		return true, sql, { obj_type=p_objType, info_id=newWkdsInfoId, info_map=wkdsInfoCache };
	end
	
	return false, nil, nil;
end

_WkdsInfoModel.getWkdsInfoInsertSqlAndCache = getWkdsInfoInsertSqlAndCache;

---------------------------------------------------------------------------
--[[
	局部函数：向Redis中保存微课的信息,对应wkds_[T_WKDS_INFO表主键]；
	参数：infoId   		原始记录的在 T_WKDS_INFO 表的ID
	参数：cacheMap  	审核人所在单位的ID
	参数：cache   	  	Redis连接
]]

local function saveWkds2Redis(self, infoId, infoMap, cache)
	
	
	--ngx.log(ngx.ERR, "===> 要保存[***试卷***]的缓存信息：<===><===><===> ", cjson.encode(infoMap), " <===><===><===>");
	
	local result, err = cache:hmset(
		"wkds_" .. infoId, 
		"wkds_id_int",         infoMap[1],
		"wkds_id_char",        infoMap[2],
		"group_id",            infoMap[3],
		"wkds_name",           infoMap[4],
		"teacher_name",        infoMap[5],
		"teacher_name_py",     infoMap[6],
		"teacher_intro",       infoMap[7],
		"person_id",           infoMap[8],
		"identity_id",         infoMap[9],
		"create_time",         infoMap[10],
		"study_instr",         infoMap[11],
		"design_instr",        infoMap[12],
		"practice_instr",      infoMap[13],
		"downloadable",        infoMap[14],
		"content_json",        infoMap[15],
		"ts",                  infoMap[16],
		"scheme_id",           infoMap[17],
		"structure_id",        infoMap[18],
		"scheme_id_char",      infoMap[19],
		"structure_id_char",   infoMap[20],
		"play_count",          infoMap[21],
		"download_count",      infoMap[22],
		"score_count",         infoMap[23],
		"score_total",         infoMap[24],
		"score_average",       infoMap[25],
		"isdraft",             infoMap[26],
		"subject_id",          infoMap[27],
		"type",                infoMap[28],
		"type_id",             infoMap[29],
		"table_pk",            infoMap[30],
		"check_status",        infoMap[31],
		"check_message",       infoMap[32],
		"wk_type",             infoMap[33],
		"wk_type_name",        infoMap[34],
		"b_delete",            infoMap[35],
        "uploader_id",         infoMap[36],
        "stage_id",            infoMap[37],
        "w_type",              infoMap[38]
	);
	
	ngx.log(ngx.ERR, "<===><===><===> 保存缓存的结果：result:[", result, "], err: [", err, "]");
	return result, err;
end

_WkdsInfoModel.saveWkds2Redis = saveWkds2Redis;

---------------------------------------------------------------------------
--[[
	局部函数：获取更新 T_WKDS_INFO 表中的B_DELETE为1的SQL语句和缓存对象
	作者：    申健 	        2015-03-31
	参数1：   wkdsIdInt  	微课在base表的ID
	参数2：   groupId  		要删除的微课记录的GROUP_ID
	返回值1： SQL语句
]]
local function updateDeleteStatus(self, wkdsIdInt, groupId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local myTs 	 	= require "resty.TS"
	local db 	 	= DBUtil: getDb();
	local currentTS = myTs.getTs();
	
	local sql = "UPDATE T_WKDS_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE WKDS_ID_INT=" .. wkdsIdInt .. " AND TYPE=1 AND GROUP_ID=" .. groupId .. ";";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=wkds_id_int,"..wkdsIdInt..";filter=type,1;filter=group_id," .. groupId .. ";filter=b_delete,0;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取审核记录失败");
		return false, nil, nil;
	end
	
	local wkdsInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);

    local cacheKey = "wkds_" .. wkdsInfoId;
	return true, sql, { obj_type=5, key=cacheKey, field_name="b_delete", field_value="1" };

end

_WkdsInfoModel.updateDeleteStatus = updateDeleteStatus;

---------------------------------------------------------------------------
--[[
	局部函数：获取更新 T_WKDS_INFO 表中的B_DELETE字段为1的SQL语句和缓存对象
	作者：    申健 	        2015-04-15
	参数1：   resIdInt  	微课在base表的ID
	参数2：   typeId  		要删除的微课记录的类型：7我的共享
	返回值1： SQL语句
]]
local function updateMyInfoDeleteStatus(self, wkdsIdInt, typeId)
	
	local DBUtil 	 = require "multi_check.model.DBUtil";
	local myTs 	 	 = require "resty.TS"
	local db 	 	 = DBUtil: getDb();
	local currentTS  = myTs.getTs();
	
	local sql = "UPDATE T_WKDS_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE WKDS_ID_INT=" .. wkdsIdInt .. " AND TYPE_ID=" .. typeId .. " AND TYPE=2 AND B_DELETE=0;";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=wkds_id_int," .. wkdsIdInt .. ";filter=type,2;filter=type_id," .. typeId .. ";filter=b_delete,0;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取审核记录失败");
		return false, nil, nil;
	end
	
	local myInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	local cacheKey = "wkds_" .. myInfoId;
	return true, sql, { obj_type=5, key=cacheKey, field_name="b_delete", field_value="1" };

end

_WkdsInfoModel.updateMyInfoDeleteStatus = updateMyInfoDeleteStatus;

---------------------------------------------------------------------------
--[[
	局部函数：判断是否需要删除 T_WKDS_INFO 表的[我的共享]数据记录
	作者：    申健 	    2015-04-15
	参数1：   delGroupIdTab  	要删除的 T_WKDS_INFO 表的GROUP_ID
	参数2：   sharedGroupIdTab  已经共享的 T_WKDS_INFO 表的GROUP_ID
	返回值：  true需要删除，false不需要删除
]]
local function _needDelMyInfo(delGroupIdTab, sharedGroupIdTab) 
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "===> sharedGroupIdTab值输出 ===> ", cjson.encode(sharedGroupIdTab));
    
    for index_shared = 1, #sharedGroupIdTab do
        local shareGroupId = sharedGroupIdTab[index_shared];
        local bDelete = false;
        for index_del = 1, #delGroupIdTab do
            local delGroupId = delGroupIdTab[index_del];
            if shareGroupId == delGroupId then
                bDelete = true;
            end
        end
        -- 如果存在没有被删除的记录，则不删除 T_WKDS_INFO 表的共享记录
        if not bDelete then
            ngx.log(ngx.ERR, "===> 判断是否需要删除 T_WKDS_INFO 表的数据 ===> [否]");
            return false;
        end;
    end
    ngx.log(ngx.ERR, "===> 判断是否需要删除 T_WKDS_INFO 表的数据 ===> [是]");
    return true;
end


---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_WKDS_INFO 表中需要删除的对象的sql语句和cache对象
	作者：    申健 	        2015-04-09
	参数1：   wkdsIdInt  	T_WKDS_INFO 表的ID
	参数2：   groupIdTab  	要删除的微课记录的GROUP_ID，table类型，支持删除多个
	返回值1： SQL语句
]]
local function getDelSqlAndCache(self, wkdsIdInt, groupIdTab)
    
    local p_myTS      = require "resty.TS"
	local p_currentTS = p_myTS.getTs();
    
    local DBUtil = require "multi_check.model.DBUtil";
    local db     = DBUtil: getDb();
    
    -- 根据group_id 获取sql语句的条件部分
    local subCondition = "filter=group_id";
    if groupIdTab ~= nil and #groupIdTab > 0 then
       
        for index=1, #groupIdTab do
            subCondition = subCondition .. "," .. groupIdTab[index];
        end
       
    end
    
    -- 查询出 T_WKDS_INFO 表对应的ID
    local sql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=wkds_id_int, " .. wkdsIdInt .. ";filter=type,1;" .. subCondition .. ";filter=b_delete,0;';";
		
    ngx.log(ngx.ERR, " ===> 查询待删除微课的语句 ===> [", sql, "]");
    
    local sqlTable 	 	= {};		
    local delCacheTable = {};
    
    local res, err, errno, sqlstate = db:query(sql);
    if not res then
        ngx.log(ngx.ERR, "===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
        -- 将数据库连接返回连接池
        DBUtil: keepDbAlive(db);
        return false, "查询数据出错。";
    end
    
    for index=1, #res do
        local wkdsInfoId   = res[index]["ID"];
        local deleteSql    = self: getDelSqlByInfoId(wkdsInfoId);
        local cacheKey     = "wkds_" .. wkdsInfoId;
        local delCacheObj  = { obj_type=5, key=cacheKey, field_name="b_delete", field_value="1" };
        table.insert(sqlTable     , deleteSql);
        table.insert(delCacheTable, delCacheObj);
    end
    
    local sharedGroupTab = self: getAllSharedGroup(wkdsIdInt);
    -- 判断是否需要删除[我的共享]的记录
    if _needDelMyInfo(groupIdTab, sharedGroupTab) then
        local succFlag, delSql, delCache = self: updateMyInfoDeleteStatus(wkdsIdInt, 7);
        table.insert(sqlTable     , delSql);
        table.insert(delCacheTable, delCache);
    end
    
    -- 将数据库连接返回连接池
 	DBUtil: keepDbAlive(db);
    
    return true, sqlTable, delCacheTable;
end

_WkdsInfoModel.getDelSqlAndCache = getDelSqlAndCache;
---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_WKDS_INFO 表中需要删除的对象的sql语句
	作者：    申健 	    2015-04-09
	参数1：   infoId  	T_WKDS_INFO 表的ID
	返回值1： SQL语句
]]
local function getDelSqlByInfoId(self, infoId) 
    local p_myTS      = require "resty.TS"
	local p_currentTS = p_myTS.getTs();
    local deleteSql   = "UPDATE T_WKDS_INFO SET B_DELETE=1, UPDATE_TS=" .. p_currentTS .. " WHERE ID=" .. infoId .. ";";
    return deleteSql;
end

_WkdsInfoModel.getDelSqlByInfoId = getDelSqlByInfoId;

---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_WKDS_INFO 表中需要删除的对象的sql语句
	作者：    申健 	    2015-04-15
	参数1：   infoId  	微课在 T_WKDS_INFO 表的ID
	返回值1： SQL语句
]]
local function getAllSharedGroup(self, wkdsIdInt) 
    local DBUtil = require "multi_check.model.DBUtil";
    local db     = DBUtil: getDb();
    
    local sql = "SELECT GROUP_ID FROM T_WKDS_INFO WHERE WKDS_ID_INT=" .. wkdsIdInt .. " AND B_DELETE=0 AND TYPE=1 AND GROUP_ID<>2;";
    local res, err, errno, sqlstate = db:query(sql);
    if not res then
        ngx.log(ngx.ERR, "===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
        -- 将数据库连接返回连接池
        DBUtil: keepDbAlive(db);
        return false, "查询数据出错。";
    end
    
    local sharedGroupTab = {};
    for index = 1, #res do
        table.insert(sharedGroupTab, tonumber(res[index]["GROUP_ID"]));
    end
    
    return sharedGroupTab;
end

_WkdsInfoModel.getAllSharedGroup = getAllSharedGroup;

---------------------------------------------------------------------------
--[[
    描述：    获取共享给指定区域的对象的INFO表的ID
    作者：    申健     2015-05-25
    参数1：   infoId   资源在 T_RESOURCE_INFO 表的ID
    返回值1： SQL语句
]]
local function getInfoIdByWkdsIdInt(self, wkdsIdInt, groupId) 
    
    local DBUtil = require "common.DBUtil";
    local sql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=wkds_id_int, " .. wkdsIdInt .. ";filter=group_id, " .. groupId .. ";filter=b_delete,0;';";
    -- ngx.log(ngx.ERR, "[sj_log] -> [wkds_info] -> sphinx sql语句：-> [", sql, "]");
    local sphinxRes = DBUtil:querySingleSql(sql);
    if not sphinxRes then
        return false, "查询数据出错。";
    end

    if #sphinxRes == 0 then
        sql = "SELECT ID FROM T_WKDS_INFO WHERE WKDS_ID_INT=" .. wkdsIdInt .. " AND GROUP_ID=" .. groupId .. " AND B_DELETE=0 AND TYPE=1;";
        -- ngx.log(ngx.ERR, "[sj_log] -> [wkds_info] -> sql语句：-> [", sql, "]");
        local res = DBUtil:querySingleSql(sql);
        if not res then
            return false, "查询数据出错。";
        end

        if #res == 0 then
            return false;
        else
            return res[1]["ID"];
        end
    else
        return sphinxRes[1]["ID"];
    end
end

_WkdsInfoModel.getInfoIdByWkdsIdInt = getInfoIdByWkdsIdInt;
---------------------------------------------------------------------------
return _WkdsInfoModel; 