-- -----------------------------------------------------------------------------------
-- 描述：资源的 model 函数类
-- 日期：2015年4月9日
-- 作者：申健
-- -----------------------------------------------------------------------------------

local _ResourceInfo = {};

local ssdbUtil = require "common.SSDBUtil";
local DBUtil   = require "multi_check.model.DBUtil";

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据应用类型的质数值获取应用类型名称
-- 作    者： 申健        2015-03-12
-- 参    数： appTypeId   应用类型质数值
-- 返 回 值： 应用类型名称
-- -----------------------------------------------------------------------------------
local function getAppTypeName(self, appTypeId, schemeId)
    
    local CacheUtil = require "multi_check.model.CacheUtil";
    local cache     = CacheUtil: getRedisConn();
    
    local myPrime           = require "resty.PRIME";
    local app_typeids       = myPrime.dec_prime(appTypeId);
    local app_type_name_tab = {};
    local app_type_name     = "";
    app_type_name_tab       = Split(app_typeids, ",");
    for i=1, #app_type_name_tab do
        local apptypename = cache:hmget("t_base_apptype_" .. schemeId .. "_" .. app_type_name_tab[i], "app_type_name")
        app_type_name = app_type_name .. "," .. tostring(apptypename[1]);
    end

    app_type_name = string.sub(app_type_name, 2, #app_type_name);
    
    -- 将Redis连接归还连接池
    CacheUtil:keepConnAlive(cache);
    return app_type_name;
end
_ResourceInfo.getAppTypeName = getAppTypeName;

-- ----------------------------------------------------------------------------------- 
-- 函数描述： 获取T_RESOURCE_INFO表新的主键ID， 用于新增记录
-- 作    者： 申健        2015-03-12
-- 参    数： 无
-- 返 回 值： 新的 T_RESOURCE_INFO 表记录的ID
-- -----------------------------------------------------------------------------------
local function getNewRecordPk()
    local  newInfoId = ssdbUtil: incr("t_resource_info_pk");
    return newInfoId;
end
_ResourceInfo.getNewRecordPk = getNewRecordPk;


-- ----------------------------------------------------------------------------------- 
-- 函数描述： 根据RESOURCE_ID_INT 获取在T_RESOURCE_INFO表中的ID
-- 作    者： 申健        2015-03-12
-- 参    数： resIdInt    资源的 RESOURCE_ID_INT
-- 返 回 值： 应用类型名称
-- -----------------------------------------------------------------------------------
function _ResourceInfo.getInfoId(resIdInt)
    local sql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int," ..resIdInt .. ";filter=group_id,2;' LIMIT 1;";
    
    local db = DBUtil: getDb();
    local dbResult, err, errno, sqlstate = db:query(sql);
    if not dbResult then
        error("在 T_RESOURCE_INFO 表中获取 RESOURCE_ID_INT 值为[", resIdInt, "] 的记录出错，错误信息：[", err, "]。");
        DBUtil: keepDbAlive(db);
        return false;
    end
    
    -- 将数据库连接返回连接池
    DBUtil: keepDbAlive(db);
    return dbResult[1].ID;
end

-- ----------------------------------------------------------------------------------- 
-- 函数描述： 判断记录是否存在
-- 作    者： 申健        2015-03-12
-- 参    数： resIdInt    资源的 RESOURCE_ID_INT
-- 参    数： groupId     共享目标的ID
-- 返 回 值： true存在， false不存在
-- -----------------------------------------------------------------------------------
function _ResourceInfo.isRecordExist(resIdInt, groupId)
    local db = DBUtil: getDb();
    
    local sql = "SELECT SQL_NO_CACHE COUNT(ID) AS ROW_COUNT FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,"..resIdInt..";filter=group_id," .. groupId .. ";filter=release_status,1,3;' LIMIT 1;";
    local dbResult, err, errno, sqlstate = db:query(sql);
    if not dbResult then
        ngx.print("{\"success\":false,\"info\":\"获取审核记录失败。\"}");
        error("在 T_RESOURCE_INFO 表中获取 RESOURCE_ID_INT 值为[", resIdInt, "], GROUP_ID为[", groupId, "]的记录出错，错误信息：[", err, "]。");
        DBUtil: keepDbAlive(db);
        return false;
    end
    
    -- 将数据库连接返回连接池
    DBUtil: keepDbAlive(db);
    
    if tonumber(dbResult[1]["ROW_COUNT"]) > 0 then
        return true;
    else
        return false;
    end
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据 RESOURCE_ID_INT 和 GROUP_ID 获取试卷记录
-- 日    期： 2015年8月25日
-- 参    数： resIdInt   试卷在 T_RESOURCE_INFO 表的ID
-- 参    数： groupId    试卷在 T_RESOURCE_INFO 表的GROUP_ID
-- 返 回 值： 返回table对象
-- -----------------------------------------------------------------------------------
function _ResourceInfo.getByBaseIdAndGroupId(self, resIdInt, groupId)
    local DBUtil    = require "common.DBUtil";
    local ssdbUtil  = require "common.SSDBUtil";
    
    local sql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,"..resIdInt..";filter=group_id," .. groupId .. ";filter=release_status,1,3;' LIMIT 1;";
    local queryResult, errInfo = DBUtil: querySingleSql(sql);
    if not queryResult then
        error(errInfo);
        return nil;
    end
    
    if #queryResult == 0 then
        return nil;
    end;
    local infoId = queryResult[1]["ID"];

    local resCache = ssdbUtil:multi_hget_hash("resource_" .. infoId, "resource_id_int", "resource_id_char");

    if resCache ~= nil then
        resCache["id"] = infoId;
    end
    return resCache;
end

-- -----------------------------------------------------------------------------------
-- 局部函数：获取更新 T_RESOURCE_INFO 表中的RELEASE_STATUS为1的SQL语句和缓存对象
-- 作者：    申健 	    2015-04-09
-- 参数1：   resIdInt  	资源在base表的ID
-- 参数2：   groupId    要删除的资源记录的GROUP_ID
-- 返回值1： SQL语句
-- -----------------------------------------------------------------------------------
local function updateDeleteStatus(self, resIdInt, groupId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local myTs 	 	= require "resty.TS"
	local db 	 	= DBUtil: getDb();
	local currentTS = myTs.getTs();
	
	local sql = "UPDATE T_RESOURCE_INFO SET RELEASE_STATUS=4, UPDATE_TS=".. currentTS .. " WHERE RESOURCE_ID_INT=" .. resIdInt .. " AND GROUP_ID=" .. groupId .. ";";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,"..resIdInt..";filter=group_id," .. groupId .. ";filter=release_status,1,3;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取审核记录失败");
		return false, nil, nil;
	end
	
	local resourceInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	local checkObjType = 1;
	local resourceInfo = {checkObjType};
	return true, sql, { obj_type=1, info_id=resourceInfoId, info_map=resourceInfo };

end

_ResourceInfo.updateDeleteStatus = updateDeleteStatus;

-- -----------------------------------------------------------------------------------
-- 局部函数：判断是否需要删除T_RESOURCE_MY_INFO表的数据对象
-- 作者：    申健 	            2015-04-15
-- 参数1：   delGroupIdTab  	要删除的 T_RESOURCE_INFO 表的GROUP_ID
-- 参数2：   sharedGroupIdTab   已经共享的 T_RESOURCE_INFO 表的GROUP_ID
-- 返回值：  true需要删除，false不需要删除
-- -----------------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------------
-- 局部函数：获取需要删除的 T_RESOURCE_INFO 表中需要删除的对象的sql语句和cache对象
-- 作者：    申健 	        2015-04-09
-- 参数1：   resIdInt  	资源在base表的ID
-- 参数2：   groupId  		要删除的资源记录的GROUP_ID
-- 返回值1： SQL语句
-- -----------------------------------------------------------------------------------
local function getDelSqlAndCache(self, resIdInt, groupIdTab)
    
    local p_myTS      = require "resty.TS"
	local p_currentTS = p_myTS.getTs();
    
    local DBUtil = require "multi_check.model.DBUtil";
    local db     = DBUtil: getDb();
    
    -- 根据group_id 获取sql语句的条件部分
    local subCondition = "filter=group_id";
    if groupIdTab ~= nil and #groupIdTab > 0 then
       
        for index=1, #groupIdTab do
            subCondition = subCondition .. "," .. groupIdTab[index];

            -- 将资源和备课修改为不通过时，需要维护对应的多级门户的统计数据
            -- local djmhTjwh = require "new_djmh.model.whdjmhtj";
            -- djmhTjwh: whdjmhtj(groupIdTab[index], resIdInt);
        end
       
    end
    
    -- 查询出 T_RESOURCE_INFO 表对应的ID
    local sql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int, " .. resIdInt .. ";" .. subCondition .. ";filter=release_status,1,3;';";
		
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
        -- local cjson = require "cjson";
        -- ngx.log(ngx.ERR, "===> res对象的参数值：===> ", cjson.encode(res));
        
        
        local resInfoId = tonumber(res[index]["ID"]);
        local cacheKey  = "resource_" .. resInfoId;
        local deleteSql = self: getDelSqlByInfoId(resInfoId);
        local delCacheObj  = { obj_type=1, key=cacheKey, field_name="release_status", field_value="4" };
        table.insert(sqlTable     , deleteSql);
        table.insert(delCacheTable, delCacheObj);
    end
    
    -- 判断是否需要删除[我的共享]的记录
    local sharedGroupTab = self: getAllSharedGroup(resIdInt);
    -- 如果要删除的groupId和该资源已经共享的群组的ID相同，则删除T_RESOURCE_MY_INFO表的数据
    -- 如果要删除的groupId多于该资源已经共享的群组的ID，同样删除T_RESOURCE_MY_INFO表的数据
    if _needDelMyInfo(groupIdTab, sharedGroupTab) then
        local resMyInfoModel = require "resource.model.ResourceMyInfo";
        local succFlag, delSql, delCache = resMyInfoModel: updateDeleteStatus(resIdInt, 7);
        table.insert(sqlTable     , delSql);
        table.insert(delCacheTable, delCache);
    end
    
    -- 将数据库连接返回连接池
 	DBUtil: keepDbAlive(db);
    
    return true, sqlTable, delCacheTable;
end

_ResourceInfo.getDelSqlAndCache = getDelSqlAndCache;
---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_RESOURCE_INFO 表中需要删除的对象的sql语句
	作者：    申健 	    2015-04-09
	参数1：   infoId  	资源在 T_RESOURCE_INFO 表的ID
	返回值1： SQL语句
]]
local function getDelSqlByInfoId(self, infoId) 
    local p_myTS      = require "resty.TS"
	local p_currentTS = p_myTS.getTs();
    local deleteSql   = "UPDATE T_RESOURCE_INFO SET RELEASE_STATUS=4, UPDATE_TS=" .. p_currentTS .. " WHERE ID=" .. infoId .. ";";
    return deleteSql;
end

_ResourceInfo.getDelSqlByInfoId = getDelSqlByInfoId;
---------------------------------------------------------------------------
--[[
	局部函数：获取需要删除的 T_RESOURCE_INFO 表中需要删除的对象的sql语句
	作者：    申健 	    2015-04-09
	参数1：   infoId  	资源在 T_RESOURCE_INFO 表的ID
	返回值1： SQL语句
]]
local function getAllSharedGroup(self, resIdInt) 
    local DBUtil = require "multi_check.model.DBUtil";
    local db     = DBUtil: getDb();
    
    local sql = "SELECT GROUP_ID FROM T_RESOURCE_INFO WHERE RESOURCE_ID_INT=" .. resIdInt .. " AND RELEASE_STATUS=1 AND GROUP_ID<>2;";
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

_ResourceInfo.getAllSharedGroup = getAllSharedGroup;

---------------------------------------------------------------------------
--[[
    描述：    获取共享给指定区域的对象的INFO表的ID
    作者：    申健     2015-04-09
    参数1：   infoId   资源在 T_RESOURCE_INFO 表的ID
    返回值1： SQL语句
]]
local function getInfoIdByResIdInt(self, resIdInt, groupId) 
    
    local DBUtil = require "common.DBUtil";
    local sql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int, " .. resIdInt .. ";filter=group_id, " .. groupId .. ";filter=release_status,1,3;';";
    -- ngx.log(ngx.ERR, "[sj_log] -> [resource_info] -> sphinx sql语句：-> [", sql, "]");
    local sphinxRes = DBUtil:querySingleSql(sql);
    if not sphinxRes then
        return false, "查询数据出错。";
    end

    if #sphinxRes == 0 then
        sql = "SELECT ID FROM T_RESOURCE_INFO WHERE RESOURCE_ID_INT=" .. resIdInt .. " AND GROUP_ID=" .. groupId .. " AND RELEASE_STATUS IN (1,3);";
        -- ngx.log(ngx.ERR, "[sj_log] -> [resource_info] -> sql语句：-> [", sql, "]");
        local res = DBUtil:querySingleSql(sql);
        if not res or #res == 0 then
            return false, "查询数据出错。";
        end

        return res[1]["ID"];
    else
        return sphinxRes[1]["ID"];
    end
end

_ResourceInfo.getInfoIdByResIdInt = getInfoIdByResIdInt;

---------------------------------------------------------------------------

return _ResourceInfo;