--[[
	局部函数：部门信息基础接口
]]
local _ClassModel = {};

--1小学  2初中  3高中  4完全中学  5九年一贯制 6十二年一贯制，7职教，8通用，9幼儿
local _classType = {};
_classType[4] = "小学";
_classType[5] = "初中";
_classType[6] = "高中";
_classType[7] = "职教";
_classType[8] = "通用";
_classType[9] = "幼儿";

---------------------------------------------------------------------------
--[[
	描述：	根据班级ID获取指定的班级信息
	参数：	classId 	 	班级ID
]]
local function getById(self, classId)
	local DBUtil = require "common.DBUtil";
    local sql = "SELECT CLASS_ID, CLASS_NAME, ENTRANCE_YEAR, STAGE_ID, BZR_ID, BUREAU_ID, B_USE, SORT_ID, CREATE_TIME FROM T_BASE_CLASS WHERE CLASS_ID="  .. classId;
    local queryResult = DBUtil: querySingleSql(sql);
	if not queryResult then
		return false;
	end
    return queryResult[1];
end

_ClassModel.getById = getById;

---------------------------------------------------------------------------
--[[
	描述：	获取指定学校下的所有班级（不分页）
	参数：	schoolId 	 	学校ID，对应BUREAU_ID字段
]]
local function getBySchoolNoPage(self, schoolId)
	local DBUtil = require "common.DBUtil";
    local sql = "SELECT T1.CLASS_ID, T1.CLASS_NAME, T1.ENTRANCE_YEAR, T1.STAGE_ID, T1.BZR_ID, T1.BUREAU_ID, T1.B_USE, T1.SORT_ID, T1.CREATE_TIME, 7 AS ORGA_TYPE, T2.PROVINCE_ID, T2.CITY_ID, T2.DISTRICT_ID FROM T_BASE_CLASS T1 INNER JOIN T_BASE_ORGANIZATION T2 ON T1.BUREAU_ID=T2.ORG_ID AND T2.ORG_TYPE=2 WHERE T1.BUREAU_ID="  .. schoolId;
    local queryResult = DBUtil: querySingleSql(sql);
	if not queryResult then
		return false;
	end
    return queryResult;
end

_ClassModel.getBySchoolNoPage = getBySchoolNoPage;

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--[[
	描述： 获取指定机构下的所有班级
	参数： paramTable 	 	办学方式：学校类型：1小学  2初中  3高中  4完全中学  5九年一贯制 6十二年一贯制，7职教，8通用，9幼儿
]]
local function queryByOrgWithPage(self, paramTable)

	local orgId      = tonumber(paramTable["org_id"]);
	local orgType    = tonumber(paramTable["org_type"]);
	local classType  = tonumber(paramTable["class_type"]);
	local className  = paramTable["class_name"];
	local pageNumber = tonumber(paramTable["pageNumber"]);
	local pageSize   = tonumber(paramTable["pageSize"]);

	local fieldTable  = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "ORG_ID"};
	local parentField = fieldTable[orgType];
	local DBUtil      = require "common.DBUtil";
	
	local resultObj   = {};
	
	local querySql = "SELECT T1.CLASS_ID, T1.CLASS_NAME, T2.ORG_ID, T2.ORG_NAME, 7 AS ORGA_TYPE, T1.STAGE_ID, T2.PROVINCE_ID, T2.CITY_ID, T2.DISTRICT_ID ";
	local whereSql = " FROM T_BASE_CLASS T1 INNER JOIN T_BASE_ORGANIZATION T2 ON T1.BUREAU_ID = T2.ORG_ID WHERE T2." .. parentField .. "=" .. orgId;

	if classType ~= nil and classType ~= 0 then -- 0为查询所有班级
		whereSql = whereSql .. " AND T1.STAGE_ID=" .. classType;
	end	

	if className ~= nil and className ~= "" then
		whereSql = whereSql .. " AND T1.CLASS_NAME LIKE '%" .. className .. "%'";
	end
	
	if pageNumber ~= nil then
		local countSql = "SELECT COUNT(1) AS TOTAL_COUNT " .. whereSql;

		local countResult = DBUtil: querySingleSql(countSql);
		if not countResult then
			return false;
		end
		local totalRow  = countResult[1]["TOTAL_COUNT"];
		local totalPage = math.floor((totalRow + pageSize - 1) / pageSize);
		local offset    = pageSize * pageNumber - pageSize;
		local limit     = pageSize;
		resultObj["totalRow"]   = totalRow;
		resultObj["totalPage"]  = totalPage;
		resultObj["pageNumber"] = pageNumber;
		resultObj["pageSize"]   = pageSize;
		
		querySql = querySql .. whereSql .. " ORDER BY T1.BUREAU_ID ASC LIMIT " .. offset .. "," .. limit .. ";";
    end
    ngx.log(ngx.ERR, "===> querySql ===> ", querySql);
	local queryResult = DBUtil: querySingleSql(querySql);
	if not queryResult then
		return false;
	end

	local classList = {};
	for index = 1, #queryResult do
		local classRecord   = queryResult[index];
		local convertRecord = {};

		convertRecord["class_id"]        = tonumber(classRecord["CLASS_ID"]);
		convertRecord["class_name"]      = classRecord["CLASS_NAME"];
		convertRecord["org_type"]        = classRecord["ORGA_TYPE"];
		convertRecord["school_id"]       = tonumber(classRecord["ORG_ID"]);
		convertRecord["school_name"]     = classRecord["ORG_NAME"];
		convertRecord["class_type"]      = tonumber(classRecord["STAGE_ID"]);
		convertRecord["class_type_name"] = _classType[convertRecord["class_type"]];
		convertRecord["province_id"]     = tonumber(classRecord["PROVINCE_ID"]);
		convertRecord["city_id"]         = tonumber(classRecord["CITY_ID"]);
		convertRecord["district_id"]     = tonumber(classRecord["DISTRICT_ID"]);

		table.insert(classList, convertRecord);
	end

	resultObj["class_list"] = classList;
	
    return resultObj;
end

_ClassModel.queryByOrgWithPage = queryByOrgWithPage;

---------------------------------------------------------------------------
--[[
	局部函数：根据多个ID获取班级
	参数：	classIds 	 	多个班级的ID
	返回值：	table对象，存储多个班级ID
]]
local function getByClassIds(self, classIds)
	
	local DBUtil = require "common.DBUtil";
	local sql = "SELECT T1.CLASS_ID, T1.CLASS_NAME, T2.ORG_ID, T2.ORG_NAME, 7 AS ORGA_TYPE, T1.STAGE_ID, T2.PROVINCE_ID, T2.CITY_ID, T2.DISTRICT_ID FROM T_BASE_CLASS T1 INNER JOIN T_BASE_ORGANIZATION T2 ON T1.BUREAU_ID=T2.ORG_ID WHERE 1=2 ";
	
	if classIds ~= nil and #classIds > 0 then
		for index = 1, #classIds do
			local classId = classIds[index];
			sql = sql .. " OR T1.CLASS_ID=" .. classId;
		end
    else
        return {};
    end

	ngx.log(ngx.ERR, "===> 根据多个ID查询学校的sql语句 ===> ", sql);
    local queryResult = DBUtil: querySingleSql(sql);
	if not queryResult then
		return false;
	end

	local classList = {};
	for index = 1, #queryResult do
		local classRecord   = queryResult[index];
		local convertRecord = {};

		convertRecord["class_id"]        = tonumber(classRecord["CLASS_ID"]);
		convertRecord["class_name"]      = classRecord["CLASS_NAME"];
		convertRecord["org_type"]        = classRecord["ORGA_TYPE"];
		convertRecord["school_id"]       = tonumber(classRecord["ORG_ID"]);
		convertRecord["school_name"]     = classRecord["ORG_NAME"];
		convertRecord["class_type"]      = tonumber(classRecord["STAGE_ID"]);
		convertRecord["class_type_name"] = _classType[convertRecord["class_type"]];
		convertRecord["province_id"]     = tonumber(classRecord["PROVINCE_ID"]);
		convertRecord["city_id"]         = tonumber(classRecord["CITY_ID"]);
		convertRecord["district_id"]     = tonumber(classRecord["DISTRICT_ID"]);

		table.insert(classList, convertRecord);
	end
    return classList;
end

_ClassModel.getByClassIds = getByClassIds;
---------------------------------------------------------------------------

return _ClassModel;