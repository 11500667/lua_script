--[[
#申健 2015-05-16
#描述：试题信息的基础函数
]]

local _QuestionInfo = {};

---------------------------------------------------------------------------
--[[
    局部函数：获取新的试题 T_TK_QUESTION_INFO 表的主键ID（从Redis中获取）
    作者： 申健 2015-05-16
    返回值：number类型，新的试题记录的ID
]]
local function getNewRecordPK(self)
    -- 获取redis连接
    local CacheUtil = require "multi_check.model.CacheUtil";
    local cache = CacheUtil: getRedisConn();
    -- 获取T_TK_QUESTION_INFO表的新的主键
    local newPK = cache:incr("t_tk_question_info_pk");
    -- 将Redis连接归还连接池
    CacheUtil:keepConnAlive(cache);
    return newPK;
end

_QuestionInfo.getNewRecordPK = getNewRecordPK;

---------------------------------------------------------------------------

local function getQuesInfoId(self, quesIdChar, strucId)
    local DBUtil = require "common.DBUtil";
    local querySql = "SELECT ID FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR=" .. ngx.quote_sql_str(quesIdChar) .. " AND STRUCTURE_ID_INT=" .. strucId .. " AND OPER_TYPE=1 LIMIT 1";
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> 获取试题INFO表ID的sql语句 -> [[[", querySql, "]]]");
    local queryResult = DBUtil:querySingleSql(querySql);
    if not queryResult then
        return false;
    end
    local infoId = queryResult[1]["ID"];
    return infoId;
end

_QuestionInfo.getQuesInfoId = getQuesInfoId;

---------------------------------------------------------------------------

local function isQuesInfoExist(self, quesIdChar, strucId, groupId)
    local DBUtil = require "common.DBUtil";
    local querySql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR=" .. ngx.quote_sql_str(quesIdChar) .. " AND STRUCTURE_ID_INT=" .. strucId .. " AND GROUP_ID=" .. groupId .. " AND OPER_TYPE=2 AND B_DELETE=0 LIMIT 1";
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> 判断试题是否存在的sql语句 -> [[[", querySql, "]]]");

    local queryResult = DBUtil:querySingleSql(querySql);
    if not queryResult then
        return false;
    end
    local  resCount = tonumber(queryResult[1]["TOTAL_ROW"]);
    return resCount>0;
end

_QuestionInfo.isQuesInfoExist = isQuesInfoExist;

---------------------------------------------------------------------------
--[[
    局部函数：获取审核通过后需要向 T_TK_QUESTION_INFO 表插入记录的sql语句和缓存对象
    参数：quesIdChar    原始记录的在 T_TK_QUESTION_INFO 表的ID
    参数：strucId       试题所在结构的ID
    参数：unitId        试题需要共享的目标的ID
    参数：objType       试题的审核类型ID
]]

local function getQuesInfoInsertSqlAndCache(self, quesIdChar, strucId, unitId, objType)
    
    local quesInfoId  = self: getQuesInfoId(quesIdChar, strucId);
    local p_myTs      = require "resty.TS"
    local currentTS = p_myTs.getTs();
    local newQuesInfoPk   = self:getNewRecordPK();
    -- 判断资源是否已经存在
    local isExist     = self: isQuesInfoExist(quesIdChar, strucId, unitId);
    
    if not isExist then
        
        local insertSql = "INSERT INTO T_TK_QUESTION_INFO (ID, QUESTION_ID_CHAR, QUESTION_TITLE, QUESTION_TIPS, QUESTION_TYPE_ID, QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, DOWN_COUNT, TS, KG_ZG, SCHEME_ID_INT, STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, UPDATE_TS, STRUCTURE_PATH, B_IN_PAPER, PAPER_ID_INT, B_DELETE, OPER_TYPE, CHECK_STATUS, CHECK_MSG, USE_COUNT, SORT_ID) SELECT " .. newQuesInfoPk .. ", QUESTION_ID_CHAR, QUESTION_TITLE, QUESTION_TIPS, QUESTION_TYPE_ID, QUESTION_DIFFICULT_ID, CREATE_PERSON, " .. unitId .. ", DOWN_COUNT, TS, KG_ZG, SCHEME_ID_INT, STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, " .. currentTS .. ", STRUCTURE_PATH, B_IN_PAPER, PAPER_ID_INT, 0 AS B_DELETE, 2 AS OPER_TYPE, 0 AS CHECK_STATUS, CHECK_MSG, USE_COUNT, SORT_ID FROM T_TK_QUESTION_INFO WHERE ID=" .. quesInfoId .. ";";

        local CacheUtil = require "multi_check.model.CacheUtil";
        local cache = CacheUtil: getRedisConn();

        local quesInfoCache = cache:hmget(
                "question_" .. quesInfoId, 
                "json_question", "json_answer", "create_person", "down_count", 
                "scheme_id_int", "question_id_char","sort_id", "b_delete"  
            );
        
        -- 将Redis连接归还连接池
        CacheUtil:keepConnAlive(cache);
        return true, insertSql, { obj_type=objType, info_id=newQuesInfoPk, info_map=quesInfoCache };
    end
    
    return false, nil, nil;
end

_QuestionInfo.getQuesInfoInsertSqlAndCache = getQuesInfoInsertSqlAndCache;
---------------------------------------------------------------------------
--[[
    局部函数：向Redis中保存试题的信息 对应 question_[T_TK_QUESTION_INFO表主键]；
    参数：infoId       原始记录的在T_SJK_PAPER_INFO表的ID
    参数：cacheMap     审核人所在单位的ID
    参数：cache        Redis连接
]]

local function saveQuestion2Redis(self, infoId, infoMap, cache)
    --ngx.log(ngx.ERR, "===> 要保存[***试题***]的缓存信息：<===><===><===> ", cjson.encode(infoMap), " <===><===><===>");
    
    local result, err = cache:hmset(
        "question_" .. infoId, 
        "json_question"     , infoMap[1],
        "json_answer"       , infoMap[2],
        "create_person"     , infoMap[3],
        "down_count"        , infoMap[4],
        "scheme_id_int"     , infoMap[5],
        "question_id_char"  , infoMap[6],
        "sort_id"           , infoMap[7],
        "b_delete"          , infoMap[8]
    );
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 保存缓存的结果：result:[", result, "], err: [", err, "]");
    return result, err;
end

_QuestionInfo.saveQuestion2Redis = saveQuestion2Redis;

---------------------------------------------------------------------------
--[[
    局部函数：更新 T_TK_QUESTION_INFO 表中的B_DELETE为1的SQL语句和缓存对象
    作者：    申健         2015-05-16
    参数1：   quesIdChar   试题的guid
    参数1：   strucId      试题所在结构的ID
    参数2：   groupId      要删除的资源记录的GROUP_ID
    返回值1： SQL语句
]]
local function updateDeleteStatus(self, quesIdChar, strucId, groupId)
    
    local DBUtil    = require "common.DBUtil";
    local myTs      = require "resty.TS"
    local currentTS = myTs.getTs();

    local querySql  = "SELECT ID FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='" .. quesIdChar .. "' AND STRUCTURE_ID_INT=" .. strucId .. " AND GROUP_ID=" .. groupId .. " AND B_DELETE=0 LIMIT 1;";
    
    local dbResult = DBUtil:querySingleSql(querySql);
    if not dbResult then
        ngx.log(ngx.ERR, "[sj_log] -> [multi_check] ===> 获取试题记录失败");
        return false, nil, nil;
    end
    
    local quesInfoId = dbResult[1]["ID"];
    
    local deleteSql  = "UPDATE T_TK_QUESTION_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE ID=" .. quesInfoId .. ";";

    local cacheKey = "question_" .. quesInfoId;
    return true, deleteSql, { obj_type=2, key=cacheKey, field_name="b_delete", field_value="1" };
end

_QuestionInfo.updateDeleteStatus = updateDeleteStatus;

---------------------------------------------------------------------------
--[[
    描述：    判断是否需要删除T_TK_QUESTION_MY_INFO表的数据对象
    作者：    申健              2015-04-15
    参数1：   delGroupIdTab     要删除的 T_TK_QUESTION_INFO 表的GROUP_ID
    参数2：   sharedGroupIdTab  已经共享的 T_TK_QUESTION_INFO 表的GROUP_ID
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
        -- 如果存在没有被删除的记录，则不删除 T_TK_QUESTION_MY_INFO 表的共享记录
        if not bDelete then
            ngx.log(ngx.ERR, "[sj_log] -> [multi_check] ===> 判断是否需要删除T_TK_QUESTION_MY_INFO表的数据 ===> [否]");
            return false;
        end;
    end
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] ===> 判断是否需要删除T_TK_QUESTION_MY_INFO表的数据 ===> [是]");
    return true;
end

---------------------------------------------------------------------------
--[[
    局部函数：获取需要删除的 T_TK_QUESTION_INFO 表中需要删除的对象的sql语句和cache对象
    作者：    申健         2015-04-09
    参数1：   quesIdChar   试题的guid
    参数1：   strucId      试题所在节点的ID
    参数2：   groupId      要删除的试题记录的GROUP_ID
    返回值1： SQL语句
]]
local function getDelSqlAndCache(self, quesIdChar, strucId, groupIdTab)
    
    local p_myTS      = require "resty.TS"
    local p_currentTS = p_myTS.getTs();
    
    local DBUtil = require "common.DBUtil";
    
    -- 根据group_id 获取sql语句的条件部分
    local subCondition = " AND (1=2 ";
    if groupIdTab ~= nil and #groupIdTab > 0 then
       
        for index=1, #groupIdTab do
            subCondition = subCondition .. " OR GROUP_ID=" .. groupIdTab[index];
        end
       
    end
    subCondition = subCondition .. ")";

    -- 查询出 T_RESOURCE_INFO 表对应的ID
    local sql = "SELECT ID FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='" .. quesIdChar .. "' AND STRUCTURE_ID_INT=" .. strucId .. subCondition .. " AND OPER_TYPE=2 AND B_DELETE=0;";
        
    ngx.log(ngx.ERR, "[sj_log] -> [multi_check] ===> 查询待删除试题的语句 ===> [", sql, "]");
    
    local sqlTable      = {};       
    local delCacheTable = {};
    
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false, "查询数据出错。";
    end
    
    for index=1, #res do
        -- local cjson = require "cjson";
        -- ngx.log(ngx.ERR, "===> 试题对象的参数值：===> ", cjson.encode(res));
        
        
        local quesInfoId   = tonumber(res[index]["ID"]);
        local cacheKey     = "question_" .. quesInfoId;
        local delCacheObj  = { obj_type=2, key=cacheKey, field_name="b_delete", field_value="1" };
        local deleteSql    = self: getDelSqlByInfoId(quesInfoId);
        table.insert(sqlTable     , deleteSql);
        table.insert(delCacheTable, delCacheObj);
    end
    
    -- 判断是否需要删除[我的共享]的记录
    local sharedGroupTab = self: getAllSharedGroup(quesIdChar, strucId);
    -- 如果要删除的groupId和该试题已经共享的群组的ID相同，则删除T_TK_QUESTION_MY_INFO表的数据
    -- 如果要删除的groupId多于该试题已经共享的群组的ID，同样删除T_TK_QUESTION_MY_INFO表的数据
    if _needDelMyInfo(groupIdTab, sharedGroupTab) then
        local quesMyInfoModel = require "question.model.QuestionMyInfo";
        local succFlag, delSql, delCache = quesMyInfoModel: updateDeleteStatus(quesIdChar, strucId, 7);
        table.insert(sqlTable     , delSql);
        table.insert(delCacheTable, delCache);
    end

    return true, sqlTable, delCacheTable;
end

_QuestionInfo.getDelSqlAndCache = getDelSqlAndCache;
---------------------------------------------------------------------------
--[[
    局部函数：获取需要删除的 T_TK_QUESTION_INFO 表中需要删除的对象的sql语句
    作者：    申健       2015-05-16
    参数1：   infoId     试题在 T_TK_QUESTION_INFO 表的ID
    返回值1： SQL语句
]]
local function getDelSqlByInfoId(self, infoId) 
    local p_myTS      = require "resty.TS"
    local p_currentTS = p_myTS.getTs();
    local deleteSql   = "UPDATE T_TK_QUESTION_INFO SET B_DELETE=1, UPDATE_TS=" .. p_currentTS .. " WHERE ID=" .. infoId .. ";";
    return deleteSql;
end

_QuestionInfo.getDelSqlByInfoId = getDelSqlByInfoId;
---------------------------------------------------------------------------
--[[
    局部函数：获取需要删除的 T_TK_QUESTION_INFO 表中需要删除的对象的sql语句
    作者：    申健           2015-05-16
    参数1：   quesIdChar     试题的GUID
    参数2：   strucId        试题的结构的ID
    返回值1： SQL语句
]]
local function getAllSharedGroup(self, quesIdChar, strucId) 
    local DBUtil = require "multi_check.model.DBUtil";
    local db     = DBUtil: getDb();
    
    local sql = "SELECT GROUP_ID FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='" .. quesIdChar .. "' AND STRUCTURE_ID_INT=" .. strucId .. " AND B_DELETE=0 AND OPER_TYPE=2;";
    local res, err, errno, sqlstate = db:query(sql);
    if not res then
        ngx.log(ngx.ERR, "[sj_log] -> [multi_check] ===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
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

_QuestionInfo.getAllSharedGroup = getAllSharedGroup;

---------------------------------------------------------------------------
return _QuestionInfo;