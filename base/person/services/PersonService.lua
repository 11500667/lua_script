--[[
	申健 	2015-04-24
	描述： 	学生信息基础接口
]]
local _PersonService = {};

-- -------------------------------------------------------------------------
--[[
	局部函数：在指定单位下根据用户名模糊查询学生
	作者： 申健 2015-03-10
	参数：unitId  单位ID
]]
local function queryTeacherByOrgWithPage(self, paramTable)

	local orgId      = tonumber(paramTable.org_id);
	local orgType    = tonumber(paramTable.org_type);
	local perNameKey = paramTable.teacher_name;
	local pageNumber = tonumber(paramTable.pageNumber);
	local pageSize   = tonumber(paramTable.pageSize);
	
	local DBUtil = require "common.DBUtil";
	
	local fieldTab = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "BUREAU_ID", "BUREAU_ID", "ORG_ID"};
	local fieldTab_name = {"PROVINCE_NAME", "CITY_NAME", "DISTRICT_NAME", "SCHOOL_NAME", "", "ORG_NAME", ""};
	ngx.log(ngx.ERR, "===> 参数：perNameKey -> [", perNameKey, "]");
	local fieldName = fieldTab[orgType];
	
	local whereSql = " FROM T_BASE_PERSON PERSON "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID "..
				"INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID "..
				"WHERE PERSON." .. fieldName .. "=" .. orgId .. " AND PERSON.IDENTITY_ID=5 " ..
                "AND PERSON.B_USE=1 ";
    
    if perNameKey ~= nil and perNameKey ~= "" then
        whereSql = whereSql .. "AND (PERSON.QP LIKE '%" .. perNameKey .. "%' OR PERSON.JP LIKE '%" .. perNameKey .. "%' OR PERSON.PERSON_NAME LIKE '%" .. perNameKey .. "%')";
    end
    
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW " .. whereSql;
	ngx.log(ngx.ERR, " ===> countSql语句 ===> ", countSql);
	local countResult = DBUtil:querySingleSql(countSql);
	if not countResult then
		return false;
	end
	local totalRow  = countResult[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset    = pageSize*pageNumber-pageSize;
	local limit     = pageSize;
	
	local querySql = "SELECT PERSON.PERSON_ID, PERSON.IDENTITY_ID, PERSON.PERSON_NAME, "..
				"PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME, "..
				"CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME, "..
				"DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME, "..
				"SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME, "..
				"ORG.ORG_ID, ORG.ORG_NAME, "..
				"PERSON.STAGE_ID, PERSON.STAGE_NAME, PERSON.SUBJECT_ID, PERSON.SUBJECT_NAME " ..
				whereSql .. " LIMIT " .. offset .. "," .. limit;
	ngx.log(ngx.ERR, " ===> querySql语句 ===> ", querySql);
	local queryResult = DBUtil:querySingleSql(querySql);
	if not queryResult then
		return false;
	end
	
	local resultListObj = {};
	for i=1, #queryResult do
		local record = {};
		record.teacher_id    = queryResult[i]["PERSON_ID"];
		record.teacher_name  = queryResult[i]["PERSON_NAME"];
		record.province_id   = queryResult[i]["PROVINCE_ID"];
		record.province_name = queryResult[i]["PROVINCE_NAME"];
		record.city_id       = queryResult[i]["CITY_ID"];
		record.city_name     = queryResult[i]["CITY_NAME"];
		record.district_id   = queryResult[i]["DISTRICT_ID"];
		record.district_name = queryResult[i]["DISTRICT_NAME"];
		record.school_id     = queryResult[i]["SCHOOL_ID"];
		record.school_name   = queryResult[i]["SCHOOL_NAME"];
		record.org_id        = queryResult[i]["ORG_ID"];
		record.org_name      = queryResult[i]["ORG_NAME"];
		
		if queryResult[i]["STAGE_ID"] == ngx.null or queryResult[i]["STAGE_ID"] == nil or queryResult[i]["STAGE_ID"]=="" then
			record.stage_id 	= 0;
			record.stage_name = "无";
			record.subject_id 	= 0;
			record.subject_name = "无";
		else
			record.stage_id 	= queryResult[i]["STAGE_ID"];
			record.stage_name 	= queryResult[i]["STAGE_NAME"];
			record.subject_id 	= queryResult[i]["SUBJECT_ID"];
			record.subject_name = queryResult[i]["SUBJECT_NAME"];
		end
		
		local orgPath = "";
		for j = orgType + 1, #fieldTab_name do
            local orgNameField = fieldTab_name[j];
            if orgNameField ~= nil and orgNameField ~= "" then
                if j== orgType + 1 then
                    orgPath = queryResult[i][orgNameField];
                else
                    orgPath = orgPath .. "--" .. queryResult[i][orgNameField];
                end
            end
		end
		record.org_path = orgPath;
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success      = true;
	resultJsonObj.totalRow     = totalRow;
	resultJsonObj.totalPage    = totalPage;
	resultJsonObj.pageNumber   = pageNumber;
	resultJsonObj.pageSize     = pageSize;
	resultJsonObj.teacher_list = resultListObj;
	
	return resultJsonObj;
end

_PersonService.queryTeacherByOrgWithPage = queryTeacherByOrgWithPage;
-- -------------------------------------------------------------------------
--[[
	描述： 	根据多个ID获取人员信息
	参数：	personIds	 	存储多个人员ID的table
	返回：	存储查询结果的Table对象
]]
local function getPersonByIds(self, personIds)
	local cjson = require "cjson";
	ngx.log(ngx.ERR, "===> 根据多个ID查询人员的参数 ===> ", cjson.encode(personIds));
	local personModel   = require "base.person.model.PersonInfoModel";
	local personResults = personModel: getByIds(personIds);

	return personResults;
end
_PersonService.getPersonByIds = getPersonByIds;
-- -------------------------------------------------------------------------
--[[
	局部函数：在指定单位下根据用户名模糊查询，结果包括教师和学生
	作者： 申健 2015-04-24
	参数： paramTable  参数table
]]
local function queryTeaAndStuByOrgWithPage(self, paramTable)

	local orgId      = paramTable.org_id;
	local orgType    = paramTable.org_type;
	local perNameKey = paramTable.person_name;
	local pageNumber = paramTable.pageNumber;
	local pageSize   = paramTable.pageSize;
	
	local DBUtil = require "multi_check.model.DBUtil";
	
	
	local stuFieldTab = {"SCHOOL.PROVINCE_ID", "SCHOOL.CITY_ID", "SCHOOL.DISTRICT_ID", "STUDENT.BUREAU_ID", "STUDENT.BUREAU_ID", "SCHOOL.ORG_ID", "CLASS.CLASS_ID"};
	local teaOrgPathField = {"PROVINCE_NAME", "CITY_NAME", "DISTRICT_NAME", "SCHOOL_NAME", "", "ORG_NAME"};
	local stuOrgPathField = {"PROVINCE_NAME", "CITY_NAME", "DISTRICT_NAME", "SCHOOL_NAME", "", "", "ORG_NAME"};
	ngx.log(ngx.ERR, "===> 参数：perNameKey -> [", perNameKey, "]");
	
	local whereSql = " FROM (SELECT PERSON.PERSON_ID, PERSON.IDENTITY_ID, PERSON.PERSON_NAME, "..
				"PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME, "..
				"CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME, "..
				"DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME, "..
				"SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME, "..
				"ORG.ORG_ID, ORG.ORG_NAME FROM T_BASE_PERSON PERSON "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID "..
				"INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID "..
				"WHERE PERSON." .. teaFieldTab[orgType] .. "=" .. unitId .. " AND (PERSON.QP LIKE '%" .. perNameKey .. "%' OR PERSON.JP LIKE '%" .. perNameKey .. "%' OR PERSON.PERSON_NAME LIKE '%" .. perNameKey .. "%') AND PERSON.IDENTITY_ID=5" ..
				" UNION " ..
				"SELECT STUDENT.STUDENT_ID AS PERSON_ID, 6 AS IDENTITY_ID,  STUDENT.STUDENT_NAME AS PEROSN_NAME, " .. 
				"PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME, "..
				"CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME, "..
				"DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME, "..
				"SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME " ..
				"CLASS.CLASS_ID AS ORG_ID, CLASS.CLASS_NAME AS ORG_NAME " ..
				"FROM T_BASE_STUDENT STUDENT "..
				"INNER JOIN T_BASE_CLASS CLASS ON CLASS.CLASS_ID=STUDETN.CLASS_ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON STUDENT.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON SCHOOL.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_GOV_CITY CITY ON SCHOOL.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON SCHOOL.PROVINCE_ID=PROVINCE.ID "..
				"WHERE " .. stuFieldTab[orgType] .. "=" .. unitId .. " AND STUDENT.STUDENT_NAME LIKE '%" .. stuNameKey .. "%') AS TEMP_PERSON  "
				
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW " .. whereSql;
	ngx.log(ngx.ERR, " ===> countSql语句 ===> ", countSql);
	local countResult = DBUtil:querySingleSql(countSql);
	if not countResult then
		return false;
	end
	local totalRow  = countResult[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset    = pageSize*pageNumber-pageSize;
	local limit     = pageSize;
	
	local querySql = "SELECT PERSON_ID, IDENTITY_ID, PERSON_NAME, PROVINCE_ID, PROVINCE_NAME,"..
				" CITY_ID, CITY_NAME, DISTRICT_ID, DISTRICT_NAME, SCHOOL_ID, SCHOOL_NAME,"..
				" ORG_ID, ORG_NAME ".. whereSql .. " LIMIT " .. offset .. "," .. limit;
	ngx.log(ngx.ERR, " ===> querySql语句 ===> ", querySql);
	local queryResult = DBUtil:querySingleSql(querySql);
	if not queryResult then
		return false;
	end
	
	local resultListObj = {};
	for i=1, #queryResult do
		local record = {};
		record.person_id     = queryResult[i]["PERSON_ID"];
		record.person_name   = queryResult[i]["PERSON_NAME"];
		record.identity_id   = queryResult[i]["IDENTITY_ID"];
		record.province_id   = queryResult[i]["PROVINCE_ID"];
		record.province_name = queryResult[i]["PROVINCE_NAME"];
		record.city_id       = queryResult[i]["CITY_ID"];
		record.city_name     = queryResult[i]["CITY_NAME"];
		record.district_id   = queryResult[i]["DISTRICT_ID"];
		record.district_name = queryResult[i]["DISTRICT_NAME"];
		record.school_id     = queryResult[i]["SCHOOL_ID"];
		record.school_name   = queryResult[i]["SCHOOL_NAME"];
		record.org_id        = queryResult[i]["ORG_ID"];
		record.org_name      = queryResult[i]["ORG_NAME"];

		local orgPath = "", orgPathField;
		if record.identity_id == 5 then
			orgPathField = teaOrgPathField;
		else
			orgPathField = stuOrgPathField;
		end
		for j = orgType + 1, #orgPathField do
			local orgNameField = orgPathField[j];
			if orgNameField == nil or orgNameField == "" then
				
			elseif j == orgType+1 then
				orgPath = queryResult[index][orgNameField];
			else
				orgPath = orgPath .. "--" .. queryResult[index][orgNameField];
			end
		end
		record.orgPath = orgPath;
		
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success      = true;
	resultJsonObj.totalRow     = totalRow;
	resultJsonObj.totalPage    = totalPage;
	resultJsonObj.pageNumber   = pageNumber;
	resultJsonObj.person_list  = resultListObj;
	
	return resultJsonObj;
end

_PersonService.queryTeaAndStuByOrgWithPage = queryTeaAndStuByOrgWithPage;

-- -------------------------------------------------------------------------
--[[
    描述： 获取教师的所有任教科目
    作者： 申健 2015-05-06
    参数： teacherId  教师ID
  返回值：存储结果的table
]]
local function getTeachSujbect(self, teacherId)
    
    local personModel  = require "base.person.model.PersonInfoModel";
    local subjectTable = personModel: getTeachSubjectByPersonId(teacherId);
    
    if not subjectTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, subject_list=subjectTable };
end

_PersonService.getTeachSujbect = getTeachSujbect;

-- -------------------------------------------------------------------------
--[[
    描述： 获取教师在指定科目下的所有任教的班级
    作者： 申健 2015-05-06
    参数： teacherId  教师ID
    参数： subjectId  科目ID
    返回值：存储结果的table
]]
local function getTeachClassesBySubject(self, teacherId, subjectId)
    
    local personModel = require "base.person.model.PersonInfoModel";
    local classTable  = personModel: getTeachClassesBySubject(teacherId, subjectId);
    
    if not classTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, class_list=classTable };
end

_PersonService.getTeachClassesBySubject = getTeachClassesBySubject;
-- -------------------------------------------------------------------------
--[[
    描述： 根绝班级ID ，获取当前学期下所有的老师
    作者： 胡悦 2015-07-07
    参数： calssId  班级ID
    返回值：存储结果的table
]]
local function getTeacherByClass(self,classId)
  
  local personModel = require "base.person.model.PersonInfoModel";
  
  local teacherTable  = personModel: getTeacherByClass(classId);
    if not teacherTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, teacher_list=teacherTable };

end
_PersonService.getTeacherByClass = getTeacherByClass;
-- -------------------------------------------------------------------------

--[[
    描述： 获取和我一个学校的老师
    作者： 胡悦 2015-07-25
    参数： identityId  身份Id
		   personId 教师ID
    返回值：存储结果的table
]]
local function getMyColleagues(self,identityId,personId)
	local personModel = require "base.person.model.PersonInfoModel";
  
    local teacherTable  = personModel: getMyColleagues(identityId,personId);
    if not teacherTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, teacher_list=teacherTable };

end
_PersonService.getMyColleagues = getMyColleagues;
-- -------------------------------------------------------------------------

--[[
    描述： 获取和我一个班级的同学
    作者： 胡悦 2015-07-25
    参数：   studentId 学生Id
    返回值：存储结果的table
]]
local function getMyClassmates(self,studentId)
	local personModel = require "base.person.model.PersonInfoModel";
  
    local studentTable  = personModel: getMyClassmates(studentId);
    if not studentTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, student_list=studentTable };

end
_PersonService.getMyClassmates = getMyClassmates;
-- -------------------------------------------------------------------------
--[[
    描述： 根据老师ID获取我的学生
    作者： 胡悦 2015-07-25
    参数：    personId 教师Id
    返回值：存储结果的table
]]
local function getMyStudents(self,personId)
	local personModel = require "base.person.model.PersonInfoModel";
  
    local studentTable  = personModel: getMyStudents(personId);
    if not studentTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, student_list=studentTable };

end
_PersonService.getMyStudents = getMyStudents;
-- -------------------------------------------------------------------------

--[[
    描述： 根据学生ID获取我的老师
    作者： 胡悦 2015-07-25
    参数：    studentId 学生ID
    返回值：存储结果的table
]]
local function getMyTeachers(self,studentId)
	local personModel = require "base.person.model.PersonInfoModel";
  
    local teacherTable  = personModel: getMyTeachers(studentId);
    if not teacherTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, teacher_list=teacherTable };

end
_PersonService.getMyTeachers = getMyTeachers;
-- -------------------------------------------------------------------------
--[[
    描述： 获取人员信息
	根据person_id和identity_id查询用户详细信息，
	1.如果是教师返回登录名login_name、真实姓名、所属省、市、区、校id及名称，2如果是学生还要增加返回班级id及班级名称
]]
local function getPersonInfo(self,person_id,identity_id)
	local personModel = require "base.person.model.PersonInfoModel";
  ngx.log(ngx.ERR,"===================================>"..person_id);
    local personTable  = personModel: getPersonInfo(person_id,identity_id)
    if not personTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=personTable };

end
_PersonService.getPersonInfo = getPersonInfo;
-- -------------------------------------------------------------------------
--[[
    描述： 根据学校ID获取所有教师
]]
local function getTeachersBySchId(self,school_id)
	local personModel = require "base.person.model.PersonInfoModel";
  
    local personTable  = personModel: getTeachersBySchId(school_id)
    if not personTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=personTable };

end
_PersonService.getTeachersBySchId = getTeachersBySchId;
-- -------------------------------------------------------------------------
--[[
    描述：需要查询所有人，包括教师、学生、家长等
]]
local function queryPersonsByKeyAndOrg(self,unitId, queryKey, pageNumber, pageSize)
	local personModel = require "base.person.model.PersonInfoModel";
  
    local personTable  = personModel: queryPersonsByKeyAndOrg(unitId, queryKey, pageNumber, pageSize)
	return personTable;

end
_PersonService.queryPersonsByKeyAndOrg = queryPersonsByKeyAndOrg;
-- -------------------------------------------------------------------------

return _PersonService;