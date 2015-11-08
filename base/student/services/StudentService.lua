--[[
	申健 	2015-04-24
	描述： 	学生信息基础接口
]]
local _StudentService = {};



---------------------------------------------------------------------------
--[[
	局部函数：在指定单位下根据用户名模糊查询学生
	作者： 申健 2015-03-10
	参数：unitId  单位ID
]]
local function queryStudentByOrgWithPage(self, paramTable)

	local orgId      = tonumber(paramTable.org_id);
	local orgType    = tonumber(paramTable.org_type);
	local stuNameKey = paramTable.student_name;
	local pageNumber = tonumber(paramTable.pageNumber);
	local pageSize   = tonumber(paramTable.pageSize);
	
	local DBUtil = require "common.DBUtil";
	local db = DBUtil: getDb();
	
	local fieldTab = {"SCHOOL.PROVINCE_ID", "SCHOOL.CITY_ID", "SCHOOL.DISTRICT_ID", "STUDENT.BUREAU_ID", "STUDENT.BUREAU_ID", "SCHOOL.ORG_ID", "CLASS.CLASS_ID"};
	local fieldTab_name = {"PROVINCE_NAME", "CITY_NAME", "DISTRICT_NAME", "SCHOOL_NAME", "", "", "CLASS_NAME"};
	ngx.log(ngx.ERR, "===> 参数：stuNameKey -> [", stuNameKey, "]");
	local fieldName = fieldTab[orgType];
	
	local whereSql = "FROM T_BASE_STUDENT STUDENT "..
				"INNER JOIN T_BASE_CLASS CLASS ON CLASS.CLASS_ID=STUDENT.CLASS_ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON STUDENT.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON SCHOOL.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_GOV_CITY CITY ON SCHOOL.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON SCHOOL.PROVINCE_ID=PROVINCE.ID "..
				"WHERE " .. fieldName .. "=" .. orgId .. " AND STUDENT.B_USE=1 ";
    if stuNameKey ~= nil and stuNameKey ~= "" then
        whereSql = whereSql .. " AND STUDENT.STUDENT_NAME LIKE '%" .. stuNameKey .. "%' "
    end
				
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW " .. whereSql;
	ngx.log(ngx.ERR, " ===> countSql语句 ===> ", countSql);
	local countResult = DBUtil:querySingleSql(countSql);
	if not countResult then
		return {success=false, info="查询数据出错！"};
	end
	local totalRow  = countResult[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset    = pageSize*pageNumber-pageSize;
	local limit     = pageSize;
	
	local querySql = "SELECT STUDENT.STUDENT_ID, STUDENT.STUDENT_NAME, " .. 
	"CLASS.CLASS_ID, CLASS.CLASS_NAME, CLASS.STAGE_ID AS CLASS_TYPE, " ..
	"PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME, "..
	"CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME, "..
	"DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME, "..
	"SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME " ..	
	whereSql .. " LIMIT " .. offset .. "," .. limit;
	ngx.log(ngx.ERR, " ===> querySql语句 ===> ", querySql);

	local queryResult = DBUtil:querySingleSql(querySql);
	if not queryResult then
		return false;
	end
	
	local resultListObj = {};
	for index = 1, #queryResult do
		local record = {};
		record.student_id    = queryResult[index]["STUDENT_ID"];
		record.student_name  = queryResult[index]["STUDENT_NAME"];
		record.class_id      = queryResult[index]["CLASS_ID"];
		record.class_name    = queryResult[index]["CLASS_NAME"];
		record.class_type    = queryResult[index]["CLASS_TYPE"];
		record.school_id     = queryResult[index]["SCHOOL_ID"];
		record.school_name   = queryResult[index]["SCHOOL_NAME"];
		record.province_id   = queryResult[index]["PROVINCE_ID"];
		record.province_name = queryResult[index]["PROVINCE_NAME"];
		record.city_id       = queryResult[index]["CITY_ID"];
		record.city_name     = queryResult[index]["CITY_NAME"];
		record.district_id   = queryResult[index]["DISTRICT_ID"];
		record.district_name = queryResult[index]["DISTRICT_NAME"];

		local org_path = "";
		for j = orgType + 1, #fieldTab_name do
			local orgNameField = fieldTab_name[j];
			if orgNameField == nil or orgNameField == "" then
				
			elseif j == orgType + 1 then
				org_path = queryResult[index][orgNameField];
			else
				org_path = org_path .. "--" .. queryResult[index][orgNameField];
			end
		end
		record.org_path = org_path;
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success       = true;
	resultJsonObj.totalRow      = totalRow;
	resultJsonObj.totalPage 	= totalPage;
	resultJsonObj.pageNumber 	= pageNumber;
	resultJsonObj.pageSize 		= pageSize;
	resultJsonObj.student_list 	= resultListObj;
	
	return resultJsonObj;
end

_StudentService.queryStudentByOrgWithPage = queryStudentByOrgWithPage;
---------------------------------------------------------------------------
--[[
	描述： 	根据多个ID获取学生信息
	参数：	studentIds	 	存储多个学生ID的table
	返回：	存储查询结果的Table对象
]]
local function getStudentByIds(self, studentIds)
	local cjson = require "cjson";
	ngx.log(ngx.ERR, "===> 根据多个ID查询学生的参数 ===> ", cjson.encode(studentIds));
	local stuModel   = require "base.student.model.Student";
	local stuResults = stuModel: getByIds(studentIds);

	return stuResults;
end

_StudentService.getStudentByIds = getStudentByIds;
---------------------------------------------------------------------------

return _StudentService;