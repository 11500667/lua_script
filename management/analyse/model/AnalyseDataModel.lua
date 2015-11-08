--[[
    #申健   2015-04-18
    #描述： 统计信息数据的Model类
]]

local _AnalyseDataModel = {};

local DBUtil = require "common.DBUtil";

----------------------------------------------------------------------------------
--[[
	函数描述： 插入按机构、平台进行统计的数据
	作者：    申健 	        2015-04-22
	参数：   recordTable  	装载数据对象的table
	返回值：  SQL语句
]]
local function getInsertGovPlatSql(self, recordTable)
	
	local sql = "INSERT INTO T_ANALYSE_GOV_PLAT (" 
            .. "PROVINCE_ID, CITY_ID, DISTRICT_ID, SCHOOL_ID, STAGE_ID, SUBJECT_ID, SCHEME_ID, STRUCTURE_ID, STRUCTURE_CODE, OBJ_ID_INT, OBJ_ID_CHAR, OBJ_TYPE, RESOURCE_ID_INT, DEST_ORG_ID, DATE_TIME, "
            .. "V" .. recordTable.map_key .."_COUNT, V" .. recordTable.map_key .. "_SIZE "
            .. ") VALUES ("
            .. recordTable.province_id .. "," .. recordTable.city_id .. ","
            .. recordTable.district_id .. "," .. recordTable.school_id .. ","
            .. recordTable.stage_id ..    "," .. recordTable.subject_id.. ","
            .. recordTable.scheme_id ..    "," .. recordTable.structure_id.. ","
            .. ngx.quote_sql_str(recordTable.structure_code) .. ","
            .. recordTable.obj_id_int ..  "," .. ngx.quote_sql_str(recordTable.obj_id_char) ..  "," 
            .. recordTable.obj_type.. ","
            .. recordTable.resource_id_int ..  ",".. recordTable.dest_org_id .. ",now(),"
            .. recordTable.count ..       "," .. recordTable.size
            .. ");";
    ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 插入统计数据(T_ANALYSE_GOV_PLAT)的sql语句：[[[", sql, "]]]");
    return sql;
    
end

_AnalyseDataModel.getInsertGovPlatSql = getInsertGovPlatSql;

----------------------------------------------------------------------------------
--[[
	函数描述： 插入按学校、个人、平台进行统计的数据
	作者：    申健 	        2015-04-22
	参数：   recordTable  	装载数据对象的table
	返回值：  SQL语句
]]
local function getInsertPersonPlatSql(self, recordTable)
	
	local sql = "INSERT INTO T_ANALYSE_PERSON_PLAT (" 
            .. "STAGE_ID, SUBJECT_ID, SCHEME_ID, STRUCTURE_ID, STRUCTURE_CODE, OBJ_ID_INT, OBJ_ID_CHAR,  OBJ_TYPE, RESOURCE_ID_INT, PERSON_ID, SCHOOL_ID, DEST_ORG_ID, DATE_TIME, "
            .. "V" .. recordTable.map_key .."_COUNT, V" .. recordTable.map_key .. "_SIZE "
            .. ") VALUES ("
            .. recordTable.stage_id .. "," .. recordTable.subject_id .. ","
            .. recordTable.scheme_id .. "," .. recordTable.structure_id .. ","
            .. ngx.quote_sql_str(recordTable.structure_code) .. ","
            .. recordTable.obj_id_int .. "," .. ngx.quote_sql_str(recordTable.obj_id_char) ..  "," 
            .. recordTable.obj_type .. ","
            .. recordTable.resource_id_int .. "," .. recordTable.person_id .. "," 
            .. recordTable.school_id .. "," .. recordTable.dest_org_id .. ",now(),"
            .. recordTable.count ..     "," .. recordTable.size
            .. ");";
    ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> 插入统计数据(T_ANALYSE_PERSON_PLAT)的sql语句：[[[", sql, "]]]");
    return sql;
    
end

_AnalyseDataModel.getInsertPersonPlatSql = getInsertPersonPlatSql;

----------------------------------------------------------------------------------
--[[
	局部函数：向组织机构（省、市、区）-下级单位统计表中插入数据
	作者：    申健 	        2015-04-18
	参数1：   recordTable  	装载数据对象的table
	返回值1： SQL语句
]]
local function getInsertGovSubjectSql(self, recordTable)
	
	local sql = "INSERT INTO T_ANALYSE_GOV_SUBJECT (" 
            .. "PROVINCE_ID, CITY_ID, DISTRICT_ID, SCHOOL_ID, PLAT_ID, STAGE_ID, DATE_TIME, "
            .. "V" .. recordTable.map_key .."_COUNT, V" .. recordTable.map_key .. "_SIZE "
            .. ") VALUES ("
            .. recordTable.province_id .. "," .. recordTable.city_id .. "," 
            .. recordTable.district_id .. "," .. recordTable.school_id .. "," 
            .. recordTable.plat_id ..      "," .. recordTable.stage_id .. ",now()," 
            .. recordTable.count ..   "," .. recordTable.size
            .. ") ;";
    
    return sql;
end

_AnalyseDataModel.getInsertGovSubjectSql = getInsertGovSubjectSql;

----------------------------------------------------------------------------------
--[[
	局部函数：向学校-个人统计表中插入数据
	作者：    申健 	        2015-04-17
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function getInsertSchoolSubjectSql(self, recordTable)
	
	local sql = "INSERT INTO T_ANALYSE_SCHOOL_PERSON (" 
            .. "SCHOOL_ID, STAGE_ID, SUBJECT_ID, PLAT_ID, PERSON_ID, DATE_TIME, "
            .. "V" .. recordTable.map_key .."_COUNT, V" .. recordTable.map_key .. "_SIZE "
            .. ") VALUES ("
            .. recordTable.school_id  .. "," .. recordTable.stage_id .. "," 
            .. recordTable.subject_id .. "," .. recordTable.plat_id  .. "," 
            .. recordTable.person_id  .. ",now()," 
            .. recordTable.count  .. "," .. recordTable.size
            .. ") ;";
    
    return sql;
end

_AnalyseDataModel.getInsertSchoolSubjectSql = getInsertSchoolSubjectSql;

----------------------------------------------------------------------------------
--[[
	描述：	 删除统计数据
	作者：    申健 	        2015-04-23
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function getDeleteGovPlatSql(self, paramTable)
    local objType = tonumber(paramTable.obj_type);
    local sql     = "";
    if objType == 3 then -- 3、试题
        sql = "DELETE FROM T_ANALYSE_GOV_PLAT WHERE OBJ_ID_CHAR=" .. ngx.quote_sql_str(paramTable.obj_id_char) .. " AND OBJ_TYPE=" .. paramTable.obj_type .. " AND STRUCTURE_ID=" .. paramTable.structure_id .. " AND DEST_ORG_ID=" .. paramTable.dest_org_id .. ";";
    else
        sql = "DELETE FROM T_ANALYSE_GOV_PLAT WHERE OBJ_ID_INT=" .. paramTable.obj_id_int .. " AND OBJ_TYPE=" .. paramTable.obj_type .. " AND DEST_ORG_ID=" .. paramTable.dest_org_id .. ";"; 
    end
    
    return sql;
end

_AnalyseDataModel.getDeleteGovPlatSql = getDeleteGovPlatSql;

----------------------------------------------------------------------------------
--[[
	描述：	 删除统计数据
	作者：    申健 	        2015-04-23
	参数1：   resIdInt  	资源在base表的ID
	参数2：   groupId  		要删除的资源记录的GROUP_ID
	返回值1： SQL语句
]]
local function getDeletePersonPlatSql(self, paramTable)
	
	local objType = tonumber(paramTable.obj_type);
    local sql     = "";
    if objType == 3 then -- 3、试题
        sql = "DELETE FROM T_ANALYSE_PERSON_PLAT WHERE OBJ_ID_CHAR=" .. ngx.quote_sql_str(paramTable.obj_id_char) .. " AND OBJ_TYPE=" .. paramTable.obj_type .. " AND STRUCTURE_ID=" .. paramTable.structure_id .. " AND PERSON_ID=" .. paramTable.person_id .. " AND DEST_ORG_ID=" .. paramTable.dest_org_id .. ";"; 
    else
        sql = "DELETE FROM T_ANALYSE_PERSON_PLAT WHERE OBJ_ID_INT=" .. paramTable.obj_id_int .. " AND OBJ_TYPE=" .. paramTable.obj_type .. " AND PERSON_ID=" .. paramTable.person_id .. " AND DEST_ORG_ID=" .. paramTable.dest_org_id .. ";"; 
    end
    
    return sql;
end

_AnalyseDataModel.getDeletePersonPlatSql = getDeletePersonPlatSql;


-- ----------------------------------------------------------------------------------
-- 函数描述： 获取更新 T_ANALYSE_WAIT_CHECK 表的sql语句
-- 日    期： 2015年9月8日
-- 参    数： name 缓存的name
-- 返 回 值： 如果有对应的缓存，则返回对应的值； 如果找不到对应的缓存，则返回false；
-- ----------------------------------------------------------------------------------
local function UpdateWaitCheck(self, paramTable)
    local sql = "";
    if paramTable.oper_flag ~= nil and paramTable.oper_flag == "incr" then -- 增加待审核条数
        local querySql = "SELECT COUNT(1) AS ROW_COUNT FROM T_ANALYSE_WAIT_CHECK WHERE UNIT_ID = " .. paramTable.unit_id .. " AND UNIT_TYPE =" .. paramTable.unit_type .. " AND STRUCTURE_ID = " .. paramTable.structure_id .. ";";
        local queryResult, err = DBUtil: querySingleSql(querySql);
        if not queryResult then
            error(err);
        end
        local recordCount = tonumber(queryResult[1]["ROW_COUNT"]);

        -- 如果记录已经存在，则更新已有的记录
        if recordCount > 0 then
            
            sql = "update t_analyse_wait_check set v" .. paramTable.map_key .. "_wait_count= if(v" .. paramTable.map_key .. "_wait_count < 0, 1, (v" .. paramTable.map_key .. "_wait_count + 1)) " .. 
            " where dest_org_id=" .. paramTable.dest_org_id .. 
            " and unit_id=" .. paramTable.unit_id .. 
            " and unit_type = " .. paramTable.unit_type .. 
            " and structure_id = " .. paramTable.structure_id .. ";";

        else -- 如果记录不存在，则插入一条新的记录
            
            sql = "insert into t_analyse_wait_check(province_id, city_id, district_id, p_school_id, c_school_id, stage_id, subject_id, scheme_id, structure_id, structure_code, dest_org_id, unit_id, unit_type, v" .. paramTable.map_key .. "_wait_count) values (" 
                .. paramTable.province_id .. ", " 
                .. paramTable.city_id .. ", " 
                .. paramTable.district_id .. ", " 
                .. paramTable.p_school_id .. ", " 
                .. paramTable.c_school_id .. ", " 
                .. paramTable.stage_id .. ", " 
                .. paramTable.subject_id .. ", " 
                .. paramTable.scheme_id .. ", " 
                .. paramTable.structure_id .. ", " 
                .. ngx.quote_sql_str(paramTable.structure_code) .. ", " 
                .. paramTable.dest_org_id .. ", " 
                .. paramTable.unit_id .. ", " 
                .. paramTable.unit_type .. ", 1);";
        end
        
    elseif paramTable.oper_flag ~= nil and paramTable.oper_flag  == "decr" then -- 减少待审核条数

        sql = "UPDATE T_ANALYSE_WAIT_CHECK SET V" .. paramTable.map_key .. "_WAIT_COUNT= IF(V" .. paramTable.map_key .. "_WAIT_COUNT > 0, (V" .. paramTable.map_key .. "_WAIT_COUNT - 1), 0) " .. 
            " WHERE DEST_ORG_ID = " .. paramTable.dest_org_id .. 
            " AND UNIT_ID = " .. paramTable.unit_id .. 
            " AND UNIT_TYPE = " .. paramTable.unit_type .. 
            " AND STRUCTURE_ID = " .. paramTable.structure_id .. ";";

    end
    return sql;
end

_AnalyseDataModel.UpdateWaitCheck = UpdateWaitCheck;

----------------------------------------------------------------------------------
return _AnalyseDataModel;