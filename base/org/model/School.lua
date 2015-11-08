--[[
	局部函数：学校信息基础接口
]]
local _SchoolModel = {};

--1小学  2初中  3高中  4完全中学  5九年一贯制 6十二年一贯制，7职教，8通用，9幼儿
local _schoolType = {"小学","初中", "高中", "完全中学", "九年一贯制", "十二年一贯制", "职教", "通用", "幼儿" };

---------------------------------------------------------------------------
--[[
	局部函数：获取人员的详细信息（待完善），包括教师和学生
	参数：	orgId 	 	人员ID
	参数：	identityId   	身份ID
]]
local function getById(self, orgId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ORG_ID, ORG_NAME, 4 AS ORGA_TYPE, PROVINCE_ID, CITY_ID, DISTRICT_ID, SCHOOL_TYPE FROM T_BASE_ORGANIZATION WHERE ORG_ID=" .. orgId;
    ngx.log(ngx.ERR, "===> 根据ID查询学校的sql语句 ===> ", sql);
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult[1];

	
end

_SchoolModel.getById = getById;

---------------------------------------------------------------------------
--[[
    描述： 根据区的ID获取学校的信息
    参数： orgId  学校的ID
    返回： 存储单个学校信息的Table对象
]]
local function getByIdFromCache(self, orgId)

    local CacheUtil = require "common.CacheUtil";
    local result = CacheUtil: hmget("t_base_organization_" .. districtId, "org_id", "org_name");
    if not result then
        return false;
    end

    return result;
end

_SchoolModel.getByIdFromCache = getByIdFromCache;

---------------------------------------------------------------------------
--[[
	局部函数：获取机构的详细信息
	参数：	orgId 	 	人员ID
	参数：	identityId   	身份ID
]]
local function getBySchoolId(self, orgId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, PROVINCENAME, 1 AS ORGA_TYPE FROM T_BASE_ORGANIZATION WHERE ORG_ID=" .. orgId;
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult[1];

	
end

_SchoolModel.getBySchoolId = getBySchoolId;

---------------------------------------------------------------------------
--[[
	局部函数：根据多个ID获取组织机构
	参数：	schoolIds 	 	多个组织机构的ID
	返回值：	table对象，存储多个   	身份ID
]]
local function getBySchoolIds(self, schoolIds)
	
	local DBUtil = require "common.DBUtil";
	local sql = "SELECT ORG_ID, ORG_NAME, 4 AS ORGA_TYPE, DISTRICT_ID AS PID, SCHOOL_TYPE, PROVINCE_ID, CITY_ID, DISTRICT_ID FROM T_BASE_ORGANIZATION WHERE 1=2 ";
	
	if schoolIds ~= nil and #schoolIds > 0 then
		for index = 1, #schoolIds do
			local schoolId = schoolIds[index];
			sql = sql .. " OR ORG_ID=" .. schoolId;
		end
	end
	ngx.log(ngx.ERR, "===> 根据多个ID查询学校的sql语句 ===> ", sql);
    local queryResult = DBUtil: querySingleSql(sql);
	if not queryResult then
		return false;
	end

	local schoolList = {};
	for index = 1, #queryResult do
		local schResRecord = queryResult[index];
		local convertRecord = {};

		convertRecord["school_id"]        = schResRecord["ORG_ID"];
		convertRecord["school_name"]      = schResRecord["ORG_NAME"];
		convertRecord["school_type"]      = tonumber(schResRecord["SCHOOL_TYPE"]);
		convertRecord["school_type_name"] = _schoolType[convertRecord["school_type"]];
		convertRecord["province_id"]      = schResRecord["PROVINCE_ID"];
		convertRecord["city_id"]          = schResRecord["CITY_ID"];
		convertRecord["district_id"]      = schResRecord["district_id"];

		table.insert(schoolList, convertRecord);
	end
    return schoolList;
end

_SchoolModel.getBySchoolIds = getBySchoolIds;

---------------------------------------------------------------------------
--[[
	局部函数：根据多个ID获取组织机构
	参数：	schoolIds 	 	多个组织机构的ID
	返回值：	table对象，存储多个   	身份ID
]]
local function getByDistrictNoPage(self, districtId)

	local DBUtil = require "common.DBUtil";
	local sql = "SELECT ORG_ID, ORG_NAME, 4 AS ORGA_TYPE, DISTRICT_ID AS PID, SCHOOL_TYPE, PROVINCE_ID, CITY_ID, DISTRICT_ID FROM T_BASE_ORGANIZATION WHERE DISTRICT_ID=" .. districtId .. " AND ORG_TYPE=2;";
	
    local queryResult = DBUtil: querySingleSql(sql);
	if not queryResult then
		return false;
	end
    return queryResult;
end

_SchoolModel.getByDistrictNoPage = getByDistrictNoPage;

---------------------------------------------------------------------------
--[[
	局部函数：获取区下的所有学校
	参数：	districtId 	 	区ID
]]
local function queryByOrg(self, paramJson)
	return self: getByDistrictIdWithPage(paramJson);
end

_SchoolModel.queryByOrg = queryByOrg;

---------------------------------------------------------------------------
--[[
	局部函数：获取区下的所有学校
	参数：	districtId 	 	区ID
	参数：	schoolType 	 	办学方式：学校类型：1小学  2初中  3高中  4完全中学  5九年一贯制 6十二年一贯制，7职教，8通用，9幼儿
]]
local function queryByOrgWithPage(self, paramTable)

	local orgId      = tonumber(paramTable["org_id"]);
	local orgType    = tonumber(paramTable["org_type"]);
	local schoolType = tonumber(paramTable["school_type"]);
	local schoolName = paramTable["school_name"];
	local pageNumber = tonumber(paramTable["pageNumber"]);
	local pageSize   = tonumber(paramTable["pageSize"]);

	local fieldTable  = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID"};
	local parentField = fieldTable[orgType];
	local DBUtil      = require "common.DBUtil";
	
	local resultObj   = {};
	
	local querySql = "SELECT ORG_ID, ORG_NAME, 4 AS ORGA_TYPE, DISTRICT_ID AS PID, SCHOOL_TYPE, PROVINCE_ID, CITY_ID, DISTRICT_ID FROM T_BASE_ORGANIZATION ";
	local whereSql = "WHERE " .. parentField .. "=" .. orgId .. " AND ORG_TYPE=2 ";

	if schoolType ~= nil and schoolType ~= 0 then -- 0为查询区下全部学校
		whereSql = whereSql .. " AND SCHOOL_TYPE=" .. schoolType;
	end	

	if schoolName ~= nil and schoolName ~= "" then
		whereSql = whereSql .. " AND ORG_NAME LIKE '%" .. schoolName .. "%'";
	end
	
	if pageNumber ~= nil then
		local countSql = "SELECT COUNT(1) AS TOTAL_COUNT FROM T_BASE_ORGANIZATION " .. whereSql;
		ngx.log(ngx.ERR, " ===> 统计数量的sql语句 ===> ", countSql);
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
		
		querySql = querySql .. whereSql .. " LIMIT " .. offset .. "," .. limit .. ";";
		ngx.log(ngx.ERR, "===> 查询组织机构的sql ===> ", querySql);
	end
	
	local queryResult = DBUtil: querySingleSql(querySql);
	if not queryResult then
		return false;
	end

	local schoolList = {};
	for index = 1, #queryResult do
		local schResRecord = queryResult[index];
		local convertRecord = {};

		convertRecord["school_id"]        = schResRecord["ORG_ID"];
		convertRecord["school_name"]      = schResRecord["ORG_NAME"];
		convertRecord["school_type"]      = tonumber(schResRecord["SCHOOL_TYPE"]);
		convertRecord["school_type_name"] = _schoolType[convertRecord["school_type"]];
		convertRecord["province_id"]      = schResRecord["PROVINCE_ID"];
		convertRecord["city_id"]          = schResRecord["CITY_ID"];
		convertRecord["district_id"]      = schResRecord["DISTRICT_ID"];
		
		table.insert(schoolList, convertRecord);
	end

	resultObj["school_list"] = schoolList;
	
    return resultObj;
end

_SchoolModel.queryByOrgWithPage = queryByOrgWithPage;

---------------------------------------------------------------------------

return _SchoolModel;