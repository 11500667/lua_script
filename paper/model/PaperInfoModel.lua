--[[
#申健 2015-03-30
#描述：试卷的基础类接口
]]

local _PaperInfoModel = {};

---------------------------------------------------------------------------
--[[
	局部函数：获取新的试卷T_SJK_PAPER_INFO表的主键ID（从SSDB中获取）
	作者： 申健 2015-03-30
	返回值：number类型，新的试卷库记录的ID
]]
local function getNewRecordPK(self)
	-- 获取redis连接
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	-- 获取T_SJK_PAPER_INFO表的新的主键
	local newPK = cache:incr("t_sjk_paper_info_pk");
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
	return newPK;
end

_PaperInfoModel.getNewRecordPK = getNewRecordPK;

--[[
	局部函数：获取T_RESOURCE_INFO表新的主键ID， 用于新增记录
]]
local function isPaperInfoExist(self, paperIdInt, groupId)
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	sql = "SELECT SQL_NO_CACHE COUNT(ID) AS ROW_COUNT FROM T_SJK_PAPER_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int," .. paperIdInt .. ";filter=group_id," .. groupId .. ";filter=b_delete,0;' LIMIT 1;";
	dbResult, err, errno, sqlstate = db:query(sql);
	if not dbResult then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false;
	end
	
	if #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取paperIdInt->[", paperIdInt, "]的试卷记录，记录是否存在:[否]");
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

_PaperInfoModel.isPaperInfoExist = isPaperInfoExist;


-- -----------------------------------------------------------------------------------
-- 函数描述： 根据 PAPER_ID_INT 和 GROUP_ID 获取试卷记录
-- 日    期： 2015年8月25日
-- 参    数： paperIdInt 试卷在 T_SJK_PAPER_INFO 表的ID
-- 参    数： groupId    试卷在 T_SJK_PAPER_INFO 表的GROUP_ID
-- 返 回 值： 返回table对象
-- -----------------------------------------------------------------------------------
local function getByBaseIdAndGroupId(self, paperIdInt, groupId)
    local DBUtil    = require "common.DBUtil";
    local cacheUtil = require "common.CacheUtil";
    
    local sql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int," .. paperIdInt .. ";filter=group_id," .. groupId .. ";filter=b_delete,0;' LIMIT 1;";
    local queryResult, errInfo = DBUtil: querySingleSql(sql);
    if not queryResult then
        error(errInfo);
        return nil;
    end
    
    if #queryResult == 0 then
        return nil;
    end;
    local infoId = queryResult[1]["ID"];

    local paperCache = cacheUtil:hmget("paper_" .. infoId, "paper_id_int", "paper_id_char", "paper_name", "paper_type");

    if paperCache ~= nil and paperCache ~= ngx.null then
        paperCache["id"] = infoId;
    end
    return paperCache;
end

_PaperInfoModel.getByBaseIdAndGroupId = getByBaseIdAndGroupId;

---------------------------------------------------------------------------
--[[
	局部函数：根据PAPER_ID_INT 获取在T_SJK_PAPER_INFO表中的ID
]]
local function getPaperInfoId(self, objIdInt)
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	sql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int,"..objIdInt..";filter=group_id,2;' LIMIT 1;";
	dbResult, err, errno, sqlstate = db:query(sql);
	if not dbResult then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false;
	end
	
	if #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取paperIdInt->[", paperIdInt, "]的试卷记录，记录是否存在:[否]");
		return false;
	end;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return dbResult[1].ID;

end

_PaperInfoModel.getPaperInfoId = getPaperInfoId;

---------------------------------------------------------------------------
--[[
	局部函数：获取审核通过后需要向T_SJK_PAPER_INFO表插入记录的sql语句和缓存对象
	参数：p_paperInfoId   原始记录的在T_RESOURCE_INFO表的ID
	参数：p_unitId   	  审核人所在单位的ID
]]

local function getPaperInfoInsertSqlAndCache(self, p_paperIdInt, p_unitId, p_objType)
	
	local paperInfoId = self: getPaperInfoId(p_paperIdInt);
	
	local p_myTs = require "resty.TS"
	local p_currentTS = p_myTs.getTs();
	local newPaperInfoId = self:getNewRecordPK();
	-- 判断资源是否已经存在
	local isExist = self: isPaperInfoExist(p_paperIdInt, p_unitId);
	
	if not isExist then
	
		local sql = "INSERT INTO T_SJK_PAPER_INFO (ID, PAPER_ID_INT, PAPER_ID_CHAR, PAPER_NAME, SCHEME_ID, STRUCTURE_ID, STRUCTURE_CODE, QUESTION_COUNT, PAPER_TYPE, PERSON_ID, IDENTITY_ID, CREATE_TIME, DOWN_COUNT, TS, UPDATE_TS, JSON_CONTENT, PAPER_PAGE, PREVIEW_STATUS, FILE_ID, FOR_URLENCODER_URL, FOR_ISO_URL, PARENT_STRUCTURE_NAME, SOURCE_ID, EXTENSION, GROUP_ID, RESOURCE_INFO_ID, B_DELETE, OPER_TYPE, PAPER_APP_TYPE, PAPER_APP_TYPE_NAME) SELECT " .. newPaperInfoId .. ", PAPER_ID_INT, PAPER_ID_CHAR, PAPER_NAME, SCHEME_ID, STRUCTURE_ID, STRUCTURE_CODE, QUESTION_COUNT, PAPER_TYPE, PERSON_ID, IDENTITY_ID, CREATE_TIME, DOWN_COUNT, TS, " .. p_currentTS .. ", JSON_CONTENT, PAPER_PAGE, PREVIEW_STATUS, FILE_ID, FOR_URLENCODER_URL, FOR_ISO_URL, PARENT_STRUCTURE_NAME, SOURCE_ID, EXTENSION, " .. p_unitId .. ", RESOURCE_INFO_ID, 0, 2, PAPER_APP_TYPE, PAPER_APP_TYPE_NAME FROM T_SJK_PAPER_INFO WHERE ID=" .. paperInfoId .. ";";
		
		local CacheUtil = require "multi_check.model.CacheUtil";
		local cache = CacheUtil: getRedisConn();
		
		local paperInfoCache = cache:hmget(
				"paper_" .. paperInfoId, 
				"paper_id_int", "paper_id_char", "paper_name", "paper_type", "paper_page", "scheme_id", 
				"structure_id", "structure_code", "parent_structure_name", "source_id", "file_id", 
				"extension", "for_iso_url", "for_urlencoder_url", "preview_status", "json_content",
				"question_count", "person_id", "identity_id", "create_time", "ts", "group_id", 
				"down_count", "resource_info_id", "b_delete", "stage_id", "subject_id", "paper_app_type",
                "paper_app_type_name"
			);
		
		-- 将Redis连接归还连接池
		CacheUtil:keepConnAlive(cache);
		return true, sql, { obj_type=p_objType, info_id=newPaperInfoId, info_map=paperInfoCache };
	end
	
	return false, nil, nil;
end

_PaperInfoModel.getPaperInfoInsertSqlAndCache = getPaperInfoInsertSqlAndCache;

---------------------------------------------------------------------------
--[[
	局部函数：向Redis中保存试卷的信息 对应 paper_[T_SJK_PAPER_INFO表主键]；
	参数：infoId   		原始记录的在T_SJK_PAPER_INFO表的ID
	参数：cacheMap  	审核人所在单位的ID
	参数：cache   	  	Redis连接
]]

local function savePaper2Redis(self, infoId, infoMap, cache)
	
	
	--ngx.log(ngx.ERR, "===> 要保存[***试卷***]的缓存信息：<===><===><===> ", cjson.encode(infoMap), " <===><===><===>");
	
	local result, err = cache:hmset(
		"paper_" .. infoId, 
		"paper_id_int", 			infoMap[1],
		"paper_id_char", 			infoMap[2],
		"paper_name",        		infoMap[3],
		"paper_type",   			infoMap[4],
		"paper_page",      			infoMap[5],
		"scheme_id",        		infoMap[6],
		"structure_id",        		infoMap[7],
		"structure_code",    		infoMap[8],
		"parent_structure_name",	infoMap[9],
		"source_id",           		infoMap[10],
		"file_id",              	infoMap[11],
		"extension",             	infoMap[12],
		"for_iso_url",            	infoMap[13],
		"for_urlencoder_url",       infoMap[14],
		"preview_status",          	infoMap[15],
		"json_content",          	infoMap[16],
		"question_count",        	infoMap[17],
		"person_id",       			infoMap[18],
		"identity_id",   			infoMap[19],
		"create_time",          	infoMap[20],
		"ts",                		infoMap[21],
		"group_id",               	infoMap[22],
		"down_count",             	infoMap[23],
		"resource_info_id",         infoMap[24],
		"b_delete",           		infoMap[25],
		"stage_id",                 infoMap[26],
        "subject_id",               infoMap[27],
        "paper_app_type",           infoMap[28],
		"paper_app_type_name",      infoMap[29]
	);
	
	ngx.log(ngx.ERR, "<===><===><===> 保存缓存的结果：result:[", result, "], err: [", err, "]");
	return result, err;
end

_PaperInfoModel.savePaper2Redis = savePaper2Redis;

---------------------------------------------------------------------------
--[[
	局部函数：获取更新T_SJK_PAPER_INFO表中的B_DELETE为1的SQL语句和缓存对象
	作者：    申健 	        2015-03-14
	参数1：   paperIdInt  	试卷在base表的ID
	参数2：   groupId  		要删除的试卷记录的GROUP_ID
	返回值1： SQL语句
]]
local function updateDeleteStatus(self, paperIdInt, groupId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local myTs 	 	= require "resty.TS"
	local db 	 	= DBUtil: getDb();
	local currentTS = myTs.getTs();
	
	local sql = "UPDATE T_SJK_PAPER_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE PAPER_ID_INT=" .. paperIdInt .. " AND GROUP_ID=" .. groupId .. ";";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int,"..paperIdInt..";filter=group_id," .. groupId .. ";filter=b_delete,0;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
    -- 将数据库连接返回连接池
    DBUtil: keepDbAlive(db);
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "[sj_log] -> [multi_check] ===> 获取试卷记录失败。");
		return false, nil, nil;
	end
	
    local paperInfoId = dbResult[1]["ID"];
    local cacheKey    = "paper_" .. paperInfoId;
	return true, sql, { obj_type=3, key=cacheKey, field_name="b_delete", field_value="1" };

end

_PaperInfoModel.updateDeleteStatus = updateDeleteStatus;

---------------------------------------------------------------------------
--[[
	局部函数：判断是否需要删除 T_SJK_PAPER_MY_INFO 表的数据对象
	作者：    申健 	    2015-04-15
	参数1：   delGroupIdTab  	要删除的 T_SJK_PAPER_MY_INFO 表的GROUP_ID
	参数2：   sharedGroupIdTab  已经共享的 T_SJK_PAPER_MY_INFO 表的GROUP_ID
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
        -- 如果存在没有被删除的记录，则不删除 T_RESOURCE_MY_INFO表的共享记录
        if not bDelete then
            ngx.log(ngx.ERR, "===> 判断是否需要删除T_RESOURCE_MY_INFO表的数据 ===> [否]");
            return false;
        end;
    end
    ngx.log(ngx.ERR, "===> 判断是否需要删除T_RESOURCE_MY_INFO表的数据 ===> [是]");
    return true;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_SJK_PAPER_INFO 表中需要删除的对象的sql语句和cache对象
	作者：    申健 	        2015-04-09
	参数1：   paperIdInt  	试卷在base表的ID
	参数2：   groupIdTab  	要删除的试卷记录的GROUP_ID，table类型，支持删除多个
	返回值1： SQL语句
]]
local function getDelSqlAndCache(self, paperIdInt, groupIdTab)
    
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
    
    -- 查询出 T_RESOURCE_INFO 表对应的ID
    local sql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int, " .. paperIdInt .. ";" .. subCondition .. ";filter=b_delete,0;';";
		
    ngx.log(ngx.ERR, " ===> 查询待删除资源的语句 ===> [", sql, "]");
    
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
        local paperInfoId  = res[index]["ID"];
        local deleteSql    = self: getDelSqlByInfoId(paperInfoId);
        local cacheKey     = "paper_" .. paperInfoId;
        local delCacheObj  = { obj_type=3, key=cacheKey, field_name="b_delete", field_value="1" };
        table.insert(sqlTable     , deleteSql);
        table.insert(delCacheTable, delCacheObj);
    end
    
    -- 判断是否需要删除[我的共享]的记录
    local sharedGroupTab = self: getAllSharedGroup(paperIdInt);
    -- 如果要删除的groupId和该资源已经共享的群组的ID相同，则删除T_RESOURCE_MY_INFO表的数据
    -- 如果要删除的groupId多于该资源已经共享的群组的ID，同样删除T_RESOURCE_MY_INFO表的数据
    if _needDelMyInfo(groupIdTab, sharedGroupTab) then
        local paperMyInfo = require "paper.model.PaperMyInfo";
        local succFlag, delSql, delCache = paperMyInfo: updateDeleteStatus(paperIdInt, 7);
        table.insert(sqlTable     , delSql);
        table.insert(delCacheTable, delCache);
    end
    
    -- 将数据库连接返回连接池
 	DBUtil: keepDbAlive(db);
    
    return true, sqlTable, delCacheTable;
end

_PaperInfoModel.getDelSqlAndCache = getDelSqlAndCache;
---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_SJK_PAPER_INFO 表中需要删除的对象的sql语句
	作者：    申健 	    2015-04-09
	参数1：   infoId  	T_SJK_PAPER_INFO 表的ID
	返回值1： SQL语句
]]
local function getDelSqlByInfoId(self, infoId) 
    local p_myTS      = require "resty.TS"
	local p_currentTS = p_myTS.getTs();
    local deleteSql   = "UPDATE T_SJK_PAPER_INFO SET B_DELETE=1, UPDATE_TS=" .. p_currentTS .. " WHERE ID=" .. infoId .. ";";
    return deleteSql;
end
_PaperInfoModel.getDelSqlByInfoId = getDelSqlByInfoId;

---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_SJK_PAPER_INFO 表中需要删除的对象的sql语句
	作者：    申健 	    2015-04-15
	参数1：   infoId  	资源在 T_SJK_PAPER_INFO 表的ID
	返回值1： SQL语句
]]
local function getAllSharedGroup(self, paperIdInt) 
    local DBUtil = require "multi_check.model.DBUtil";
    local db     = DBUtil: getDb();
    
    local sql = "SELECT GROUP_ID FROM T_SJK_PAPER_INFO WHERE PAPER_ID_INT=" .. paperIdInt .. " AND B_DELETE=0 AND GROUP_ID<>2;";
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

_PaperInfoModel.getAllSharedGroup = getAllSharedGroup;
---------------------------------------------------------------------------

return _PaperInfoModel; 