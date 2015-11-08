--[[
    申健  2015-05-25
    描述：在资源列表中进行推荐
]]

local cacheUtil = require "common.CacheUtil";
local ssdbUtil  = require "common.SSDBUtil";
local DBUtil    = require "common.DBUtil";

local _Recommend = {};


---------------------------------------------------------------------------
--[[
    描述：根据对象的base_id获取推荐的对象ID
    参数：paramJson      参数字符串
]]
local function  getRecommendByIds(self, paramJson)
    
    local objType = tonumber(paramJson.obj_type);
    local objIds  = paramJson.obj_ids;
    local unitId  = paramJson.unit_id;
    local recomTypeTable = { "zy", "st", "sj", "bk", "wk"}; -- 1:资源  2:微课  3:备课  4:试卷

    local resultTable = {};
    -- ngx.log(ngx.ERR, "[sj_log] -> [recommend] -> obj_type的类型:[", type(objType), "], obj_type's value : [", objType, "]");
    if objType == 1 then -- 资源
        local resInfoModel = require "resource.model.ResourceInfo";
        for i = 1, #objIds do
            local resIdInt = objIds[i];
            local infoId   = resInfoModel: getInfoIdByResIdInt(resIdInt, unitId);
            local record   = {};
            if infoId then
                local isRecommend   = self: isObjRecommended(unitId, recomTypeTable[objType], infoId);
                -- record.obj_id_int  = resIdInt;
                record.info_id      = infoId;
                record.is_recommend = isRecommend;
                resultTable[tostring(resIdInt)] = record;
                -- table.insert(resultTable, record);
            else
                record.info_id      = 0;
                record.is_recommend = false;
                resultTable[tostring(resIdInt)] = record;
            end
        end
    elseif objType == 2 then -- 试题

    elseif objType == 3 then -- 试卷

    elseif objType == 4 then -- 备课

    elseif objType == 5 then -- 微课
        local wkdsModel = require "wkds.model.WkdsModel";
        for i = 1, #objIds do
            local wkdsIdInt = objIds[i];
            local infoId    = wkdsModel: getInfoIdByWkdsIdInt(wkdsIdInt, unitId);
            local record    = {};
            if infoId then
                local isRecommend  = self: isObjRecommended(unitId, recomTypeTable[objType], infoId);
                -- record.obj_id_int  = wkdsIdInt;
                record.info_id     = infoId;
                record.is_recommend = isRecommend;
                resultTable[tostring(wkdsIdInt)] = record;
                -- table.insert(resultTable, record);
            else
                record.info_id      = 0;
                record.is_recommend = false;
                resultTable[tostring(wkdsIdInt)] = record;
            end
        end
    end

    local resultObj       = {};
    resultObj.success     = true;
    resultObj.result_list = resultTable;

    return resultObj;
end

_Recommend.getRecommendByIds = getRecommendByIds;

---------------------------------------------------------------------------
--[[
    描述：判断对象是否被推荐过
    参数：unitId      被推荐的单位
    参数：recType     推荐的类型：1资源，2微课，3备课，4试卷
    参数：objInfoId   被推荐的资源在INFO表的ID
    返回值：true已经被推荐，false未被推荐
]]
local function isObjRecommended(self, unitId, recType, objInfoId)
    local ssdb_db = ssdbUtil: getDb();

    -- ngx.log(ngx.ERR, "[sj_log] -> [recommend] -> [zexists tuijian_" .. recType .. "_" .. unitId .. " " .. objInfoId .. "]");
    local resultTab = ssdb_db: zexists("tuijian_" .. recType .. "_" .. unitId, tostring(objInfoId));
    if resultTab == nil or resultTab == ngx.null then
        return false;
    end
    local result = resultTab[1];
    -- ngx.log(ngx.ERR, "[sj_log] -> [recommend] -> zexists tuijian_" .. recType .. "_" .. unitId .. " " .. objInfoId .. ", value:[" .. result .. "]");
    if result == "1" then
        return true;
    else
        return false;
    end
end

_Recommend.isObjRecommended = isObjRecommended;
---------------------------------------------------------------------------
--[[
    描述：  删除推荐的记录
    参数：  paramTable  table类型变量，存储了需要的参数
    返回值：true删除成功，false删除失败
]]
local function delRecommendData(self, paramTable)
    
    local recomTypeTable = { "zy", "st", "sj", "bk", "wk"}; -- 1:资源  2:微课  3:备课  4:试卷
    
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log]->[recommend]-> paramTable 的值为 : [", cjson.encode(paramTable), "]");

    local objIdInt   = paramTable["OBJ_ID_INT"];
    local objIdChar  = paramTable["OBJ_ID_CHAR"];
    local personId   = paramTable["SHARE_PERSON_ID"];
    local stageId    = paramTable["STAGE_ID"];
    local subjectId  = paramTable["SUBJECT_ID"];
    local groupIdTab = paramTable["GROUP_IDS"];
    -- 多级审核的类型：1资源，2试题，3试卷，4备课，5微课
    local objType    = tonumber(paramTable["OBJ_TYPE"]); 
    local sysType    = recomTypeTable[objType];
    
    if groupIdTab == nil or groupIdTab == ngx.null or #groupIdTab == 0 then
        return false;
    end

    --连接SSDB
    local ssdb    = require "resty.ssdb"
    local ssdb_db = ssdb:new()
    local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
    if not ok then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    for index = 1, #groupIdTab do
        
        local groupId = tonumber(groupIdTab[index]);
        local infoId     = nil;
        if groupId ~= 0 then
            if objType == 1 then -- 资源
                local resInfoModel = require "resource.model.ResourceInfo";
                infoId   = resInfoModel: getInfoIdByResIdInt(objIdInt, groupId);
            elseif objType == 2 then -- 试题

            elseif objType == 3 then -- 试卷

            elseif objType == 4 then -- 备课

            elseif objType == 5 then -- 微课
                local wkdsModel = require "wkds.model.WkdsModel";
                infoId    = wkdsModel: getInfoIdByWkdsIdInt(objIdInt, groupId);
            end
        end
        
        if infoId ~= nil and infoId ~= false then
            ngx.log(ngx.ERR, "[sj_log]->[recommend] -> ssdb_db:zdel(\"tuijian_\"" .. sysType .. "_" .. groupId, ", ", infoId, ")");
            ssdb_db:zdel("tuijian_" .. sysType .. "_" .. groupId, infoId);
            ssdb_db:zdel("tuijian_" .. sysType .. "_" .. groupId .. "_" .. stageId, infoId);
            ssdb_db:zdel("tuijian_" .. sysType .. "_" .. groupId .. "_" .. stageId .. "_" .. subjectId, infoId);

            --删除人员的相关记录
            ssdb_db:zdel("tuijian_" .. sysType .. "_" .. groupId .. "_" .. personId, infoId);
            ssdb_db:zdel("tuijian_" .. sysType .. "_" .. groupId .. "_" .. stageId .. "_" .. personId, infoId);
            ssdb_db:zdel("tuijian_" .. sysType .. "_" .. groupId .. "_" .. stageId .. "_" .. subjectId .. "_" .. personId, infoId);
        end
    end

    --放回到SSDB连接池
    ssdb_db:set_keepalive(0,v_pool_size);

    return true;
end

_Recommend.delRecommendData = delRecommendData;
-- -----------------------------------------------------------------------------------
-- 函数描述： 保存推荐记录
-- 日    期： 2015年8月20日
-- 作    者： 申健
-- 参    数： paramTable 保存参数的table对象
-- 返 回 值： boolean类型：true保存成功，false保存失败
-- -----------------------------------------------------------------------------------
function _Recommend:saveRecommend(paramTable)
    
    local objType   = paramTable["obj_type"];
    local objIdInt  = paramTable["obj_id_int"];
    local objIdChar = paramTable["obj_id_char"];
    local objInfoId = paramTable["obj_info_id"];
    local stageId   = paramTable["stage_id"];
    local subjectId = paramTable["subject_id"];
    local personId  = paramTable["person_id"];
    local unitId    = paramTable["unit_id"];
    local sortTS    = paramTable["sort_ts"];
    local bTop      = paramTable["b_top"];
    ngx.ctx["new_info_id"] = objInfoId;

    local insertSql = "INSERT INTO T_BASE_CHECK_RECOMMEND (OBJ_TYPE, OBJ_ID_INT, OBJ_ID_CHAR, OBJ_INFO_ID, STAGE_ID, SUBJECT_ID, PERSON_ID, ORG_ID, SORT_TS, B_TOP, OPER_TIME) VALUES (" .. objType .. ", " .. objIdInt .. ", " .. ngx.quote_sql_str(objIdChar) .. ", " .. objInfoId .. ", " .. stageId .. ", " .. subjectId .. ", " .. personId .. ", " .. unitId .. ", " .. sortTS .. ", " .. bTop .. ", NOW());";

    local insertResult = DBUtil: querySingleSql(insertSql);

    if not insertResult then
        return false;
    end
    return true;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 保存推荐记录
-- 日    期： 2015年8月20日
-- 作    者： 申健
-- 参    数： paramTable 保存参数的table对象
-- 返 回 值： boolean类型：true保存成功，false保存失败
-- -----------------------------------------------------------------------------------
local function updateRecommend(self, paramTable)
    local objInfoId = paramTable["obj_info_id"];
    if objInfoId == nil or objInfoId == ngx.null then
        error("obj_info_id 不能为空！");
    end

    local unitId = paramTable["unit_id"];
    if unitId == nil or unitId == ngx.null then
        error("unit_id 不能为空！");
    end

    local objType   = paramTable["obj_type"];
    if objType == nil or objType == ngx.null then
        error("obj_type 不能为空！");
    end

    local fieldTable = {};
    
    local objIdInt  = paramTable["obj_id_int"];
    if objIdInt ~= nil and objIdInt ~= ngx.null then
        fieldTable["OBJ_ID_INT"] = objIdInt;
    end

    local objIdChar = paramTable["obj_id_char"];
    if objIdChar ~= nil and objIdChar ~= ngx.null then
        fieldTable["OBJ_ID_CHAR"] = ngx.quote_sql_str(objIdChar);
    end

    local stageId   = paramTable["stage_id"];
    if stageId ~= nil and stageId ~= ngx.null then
        fieldTable["STAGE_ID"] = stageId;
    end

    local subjectId = paramTable["subject_id"];
    if subjectId ~= nil and subjectId ~= ngx.null then
        fieldTable["SUBJECT_ID"] = subjectId;
    end

    local personId  = paramTable["person_id"];
    if personId ~= nil and personId ~= ngx.null then
        fieldTable["PERSON_ID"] = personId;
    end

    local sortTS    = paramTable["sort_ts"];
    if sortTS ~= nil and sortTS ~= ngx.null then
        fieldTable["SORT_TS"] = sortTS;
    end

    local bTop      = paramTable["b_top"];
    if bTop ~= nil and bTop ~= ngx.null then
        fieldTable["B_TOP"] = bTop;
    end

    local updateSql = "UPDATE T_BASE_CHECK_RECOMMEND SET ";
    if next(fieldTable) ~= nil then
        for field, value in pairs(fieldTable) do
            updateSql = updateSql .. " " .. field .. " = " .. value .. ",";
        end
    else
        return false, "没有获取到需要更新的字段";
    end
    updateSql = string.sub(updateSql, 1, string.len(updateSql) - 1);
    updateSql = updateSql .. " WHERE OBJ_INFO_ID = " .. objInfoId .. " AND OBJ_TYPE = ".. objType .. " AND ORG_ID = " .. unitId .. ";";

    ngx.log(ngx.ERR, "\n [sj_log] -> [更新推荐信息] -> updateSql : [", updateSql, "] \n");
    local updateResult, err = DBUtil: querySingleSql(updateSql);

    if not updateResult then
        error(err);
        return false;
    end
    return true;
end

_Recommend.updateRecommend = updateRecommend;

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据推荐的类型获取多级审核的类型
-- 日    期： 2015年8月22日
-- 作    者： 申健
-- 参    数： recommendType 推荐的类型
-- 返 回 值： objType：1资源，2试题，3试卷，4备课，5微课
-- -----------------------------------------------------------------------------------
function _Recommend:getObjIdInt(objType, objInfoId)
    if objType == 1 or objType == 4 then -- 资源、备课
        local result = ssdbUtil: multi_hget_hash("resource_" .. objInfoId, "resource_id_int", "resource_id_char");
        ngx.log(ngx.ERR, "\n\n[sj_log] -> [Recommend] -> [getObjIdInt] -> 缓存的结果：[", encodeJson(result), "]");
        return tonumber(result["resource_id_int"]), result["resource_id_char"];
    elseif objType == 2 then -- 试题
        local result = cacheUtil: hget("question_" .. objInfoId, "question_id_char");
        return 0, result;
    elseif objType == 3 then -- 试卷
        local result = cacheUtil: hmget("paper_" .. objInfoId, "paper_id_int", "paper_id_char");
        return tonumber(result["paper_id_int"]), result["paper_id_char"];
    elseif objType == 5 then -- 备课
        local result = cacheUtil: hmget("wkds_" .. objInfoId, "wkds_id_int", "wkds_id_char");
        return tonumber(result["wkds_id_int"]), result["wkds_id_char"];
    end

    return 0, "-1";
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据推荐的类型获取多级审核的类型
-- 日    期： 2015年8月22日
-- 作    者： 申健
-- 参    数： recommendType 推荐的类型
-- 返 回 值： objType：1资源，2试题，3试卷，4备课，5微课
-- -----------------------------------------------------------------------------------
function _Recommend:getObjType(recommendType) 
    local objType = 0;
    if recommendType == "zy" then -- 资源
        return 1;
    elseif recommendType == "wk" then -- 微课
        objType = 5;
    elseif recommendType == "bk" then -- 备课
        objType = 4;
    elseif recommendType == "sj" then -- 试卷
        objType = 3;
    end

    return objType;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据推荐的类型获取多级审核的类型
-- 日    期： 2015年8月22日
-- 作    者： 申健
-- 参    数： recommendType 推荐的类型
-- 返 回 值： objType：1资源，2试题，3试卷，4备课，5微课
-- -----------------------------------------------------------------------------------
function _Recommend:getObjTypeBySysTypeInt(sysType) 
    local objType = 0;
    if sysType == "1" then -- 资源
        return 1;
    elseif sysType == "2" then -- 微课
        objType = 5;
    elseif sysType == "3" then -- 备课
        objType = 4;
    elseif sysType == "4" then -- 试卷
        objType = 3;
    end

    return objType;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 删除推荐记录
-- 日    期： 2015年8月24日
-- 作    者： 申健
-- 参    数： paramTable 保存参数的table对象
-- 返 回 值： boolean类型：true保存成功，false保存失败
-- -----------------------------------------------------------------------------------
function _Recommend:delRecommend(paramTable)
    
    -- 对象类型：1资源，2试题，3试卷，4备课，5微课
    local objType   = paramTable["obj_type"];
    local objInfoId = paramTable["obj_info_id"];
    local orgId     = paramTable["org_id"];

    local insertSql = "DELETE FROM T_BASE_CHECK_RECOMMEND WHERE OBJ_TYPE=" .. objType .. " AND OBJ_INFO_ID =" .. objInfoId .. " AND ORG_ID = " .. orgId .. ";";
    ngx.log(ngx.ERR, "[sj_log] -> [recommend] -> insertSql: [", insertSql, "]");
    local insertResult = DBUtil: querySingleSql(insertSql);

    if not insertResult then
        return false;
    end
    return true;
end


return _Recommend;