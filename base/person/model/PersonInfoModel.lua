--[[
	局部函数：人员信息基础接口
]]
local _PersonInfoModel = {};

---------------------------------------------------------------------------
--[[
	局部函数：获取人员的详细信息（待完善），包括教师和学生
	参数：	personId 	 	人员ID
	参数：	identityId   	身份ID
]]
local function getPersonDetail(self, personId, identityId)
	
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	
	local result, err = cache: hmget("person_" .. personId .. "_" .. identityId, "person_name", "sheng", "shi", "qu", "xiao", "bm");
	if not result or result == ngx.null then 
		CacheUtil: keepConnAlive(cache);
		return false;
	end
	
	local record = {};
	record.person_name 	= result[1];
	record.province_id 	= result[2];
	record.city_id 		= result[3];
	record.district_id 	= result[4];
	record.school_id 	= result[5];
	record.org_id 		= result[6];
	
	CacheUtil: keepConnAlive(cache);
	return record;
end

_PersonInfoModel.getPersonDetail = getPersonDetail;

---------------------------------------------------------------------------
--[[
	局部函数：获取人员的姓名
	参数：	personId 	 	人员ID
	参数：	identityId   	身份ID
]]
local function getPersonName(self, personId, identityId)
	
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	
	local result, err = cache: hmget("person_" .. personId .. "_" .. identityId, "person_name");
	if not result or result == ngx.null then 
		CacheUtil: keepConnAlive(cache);
		return false;
	end
	
	CacheUtil: keepConnAlive(cache);
	return result[1];
end

_PersonInfoModel.getPersonName = getPersonName;


---------------------------------------------------------------------------
--[[
	描述：	根据多个ID获取人员
	参数：	personIds 	 多个人员的ID
	返回值：	table对象，存储多个人员的ID
]]
local function getByIds(self, personIds)
	
	local DBUtil = require "common.DBUtil";
	local sql = "SELECT T1.PERSON_NAME, T1.PERSON_ID, T1.IDENTITY_ID, T1.STAGE_ID, T1.STAGE_NAME, T1.SUBJECT_ID, T1.SUBJECT_NAME, T2.ORG_ID, T2.ORG_NAME FROM T_BASE_PERSON T1 INNER JOIN T_BASE_ORGANIZATION T2 ON T1.BUREAU_ID=T2.ORG_ID WHERE T1.B_USE=1 ";
	
	if personIds ~= nil and #personIds > 0 then
		for index = 1, #personIds do
            local personId = personIds[index];
            if index == 1 then
                sql = sql .. " AND (T1.PERSON_ID=" .. personId;
            else
                sql = sql .. " OR T1.PERSON_ID=" .. personId;
            end

            if index == #personIds then
                sql = sql .. ")";
            end
		end
    else
        return {};
    end

	ngx.log(ngx.ERR, "[sj_log]->[person_info]-> 根据多个ID查询人员的sql语句 ===> ", sql);
    local queryResult = DBUtil: querySingleSql(sql);
	if not queryResult then
		return false;
	end

	local teacherList = {};
	for index = 1, #queryResult do
		local stuRecord = queryResult[index];
		local convertRecord = {};

		convertRecord["person_id"]   = stuRecord["PERSON_ID"];
		convertRecord["identity_id"] = stuRecord["IDENTITY_ID"];
		convertRecord["person_name"] = stuRecord["PERSON_NAME"];
		convertRecord["school_id"]   = tonumber(stuRecord["ORG_ID"]);
		convertRecord["school_name"] = stuRecord["ORG_NAME"];
		convertRecord["province_id"] = stuRecord["PROVINCE_ID"];
		convertRecord["city_id"]     = stuRecord["CITY_ID"];
		convertRecord["district_id"] = stuRecord["DISTRICT_ID"];

		if stuRecord["STAGE_ID"] == ngx.null or stuRecord["STAGE_ID"] == nil or stuRecord["STAGE_ID"]=="" then
			convertRecord["stage_id"]     = 0;
			convertRecord["stage_name"]   = "无";
			convertRecord["subject_id"]   = 0;
			convertRecord["subject_name"] = "无";
		else
			convertRecord["stage_id"]     = stuRecord["STAGE_ID"];
			convertRecord["stage_name"]   = stuRecord["STAGE_NAME"];
			convertRecord["subject_id"]   = stuRecord["SUBJECT_ID"];
			convertRecord["subject_name"] = stuRecord["SUBJECT_NAME"];
		end
		table.insert(teacherList, convertRecord);
	end
    return teacherList;
end

_PersonInfoModel.getByIds = getByIds;
---------------------------------------------------------------------------

--[[
	描述： 获取教师的任教科目
	作者： 申健 2015-05-04
	参数： teacherId  教师ID
]]
local function getTeachSubjectByPersonId(self, teacherId)

    local sql = "SELECT DISTINCT STAGE.STAGE_ID, STAGE.STAGE_NAME, T1.SUBJECT_ID, T2.SUBJECT_NAME, IF(T3.SCHEME_ID IS NULL, 0, 1) AS KNOW_EXIST FROM T_BASE_CLASS_SUBJECT T1 INNER JOIN T_DM_SUBJECT T2 ON T1.SUBJECT_ID=T2.SUBJECT_ID INNER JOIN T_DM_STAGE STAGE ON T2.STAGE_ID=STAGE.STAGE_ID LEFT OUTER JOIN T_RESOURCE_SCHEME T3 ON T1.SUBJECT_ID=T3.SUBJECT_ID AND T3.TYPE_ID=2 AND T3.B_USE=1 WHERE T1.TEACHER_ID=" .. teacherId .. " ORDER BY T2.STAGE_ID, T2.SUBJECT_ID";
    ngx.log(ngx.ERR, "[sj_log]->[person_info]-> 查询教师任教科目的Sql语句 ===> [[[", sql, "]]]");

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return false;
    end
    
    local resultTable = {};
    for index=1, #queryResult do
        local record    = queryResult[index];
        local resultObj = {};
        resultObj["stage_id"]        = record["STAGE_ID"];
        resultObj["stage_name"]      = record["STAGE_NAME"];
        resultObj["subject_id"]      = record["SUBJECT_ID"];
        resultObj["subject_name"]    = record["SUBJECT_NAME"];
        resultObj["knowledge_exist"] = record["KNOW_EXIST"];
    	
        table.insert(resultTable, resultObj);
    end
    
    return resultTable;
end

_PersonInfoModel.getTeachSubjectByPersonId = getTeachSubjectByPersonId;


---------------------------------------------------------------------------

--[[
	描述： 获取教师指定科目下任教的班级
	作者： 申健 2015-05-04
	参数： teacherId  教师ID
	参数： subjectId  科目ID
]]
local function getTeachClassesBySubject(self, teacherId, subjectId)

    local sql = "SELECT T1.CLASS_ID, T2.CLASS_NAME FROM T_BASE_CLASS_SUBJECT T1 INNER JOIN T_BASE_CLASS T2 ON T1.CLASS_ID=T2.CLASS_ID WHERE TEACHER_ID=" .. teacherId .. " AND SUBJECT_ID=" .. subjectId .. " ORDER BY CLASS_ID";
    ngx.log(ngx.ERR, "[sj_log]->[person_info]-> 查询在科目[", subjectId, "]下，教师任教班级的Sql语句 ===> [[[", sql, "]]]");

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return false;
    end
    
    local resultTable = {};
    for index=1, #queryResult do
        local record = queryResult[index];
        table.insert(resultTable, { class_id=record["CLASS_ID"], class_name=record["CLASS_NAME"] } );
    end
    
    return resultTable;
end

_PersonInfoModel.getTeachClassesBySubject = getTeachClassesBySubject;


---------------------------------------------------------------------------
--[[
    描述： 根绝班级ID ，获取当前学期下所有的老师
    作者： 胡悦 2015-07-07
    参数： calssId  班级ID
]]
local function getTeacherByClass(self,classId)
	local query_term_sql = "select xq_id from t_base_term where sfdqxq=1";
	ngx.log(ngx.ERR, "[hy_log]->[person_info]-> 查询当前学期的Sql语句 ===> [[["..query_term_sql.."]]]");
	local DBUtil      = require "common.DBUtil";
    local queryTermResult = DBUtil: querySingleSql(query_term_sql);
    if not queryTermResult then
        return false;
    end
	local xqId = queryTermResult[1]["xq_id"];
	local query_teacher_sql = "select  distinct(cs.teacher_id),bp.person_name from t_base_class_subject cs join t_base_person bp on cs.teacher_id= bp.person_id where  cs.xq_id = "..xqId.." and cs.class_id = "..classId.." and cs.b_use=1";
	local queryTeacherResult = DBUtil: querySingleSql(query_teacher_sql);
	local resultTable = {};
    for index=1, #queryTeacherResult do
        local record = queryTeacherResult[index];
        table.insert(resultTable, { person_id=record["teacher_id"], person_name=record["person_name"] } );
    end
    
    return resultTable;

end

_PersonInfoModel.getTeacherByClass = getTeacherByClass;
---------------------------------------------------------------------------
--[[
	描述： 通过班级和学科获得任教教师
	作者： 崔金龙 2015-05-04
	参数： class_id,subject_id
]]
local function getTeachByClassSubject(self, class_id,subject_id)
    local sql = "SELECT teacher_id from T_BASE_CLASS_SUBJECT "..
            "where b_use=1 AND CLASS_ID=" .. class_id .. " and SUBJECT_ID="..subject_id..
            " and XQ_ID = (SELECT XQ_ID from t_base_term where SFDQXQ=1) LIMIT 1";
    --ngx.log(ngx.ERR,"#####################"..sql)
    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return false;
    end
    if queryResult and queryResult[1] then
        return queryResult[1].teacher_id;
    else
        return "";
    end
end
_PersonInfoModel.getTeachByClassSubject = getTeachByClassSubject;

---------------------------------------------------------------------------

--[[
    描述： 获取和我一个学校的老师
    作者： 胡悦 2015-07-25
    参数： identityId  身份Id
		   personId 教师ID
    返回值：存储结果的table
]]
local function getMyColleagues(self,identityId,personId)
	local query_bureau_sql = "select bureau_id,person_id from t_base_person where person_id = "..personId.." and identity_id = "..identityId;
	ngx.log(ngx.ERR, "[hy_log]->[person_info]-> 查询当前教师所在的学校的Sql语句 ===> [[["..query_bureau_sql.."]]]");
	local DBUtil      = require "common.DBUtil";
    local queryBureauResult = DBUtil: querySingleSql(query_bureau_sql);
    if not queryBureauResult then
        return false;
    end
	local bureau_id = queryBureauResult[1]["bureau_id"];
	local query_teacher_sql = "select person_id from t_base_person where bureau_id = "..bureau_id.." and identity_id ="..identityId.." and person_id <> "..personId;
	local queryTeacherResult = DBUtil: querySingleSql(query_teacher_sql);
	local resultTable = {};
    for index=1, #queryTeacherResult do
        local record = queryTeacherResult[index];
        table.insert(resultTable, { person_id=record["person_id"], identity_id= identityId} );
    end
    
    return resultTable;

end

_PersonInfoModel.getMyColleagues = getMyColleagues;
---------------------------------------------------------------------------

--[[
    描述： 获取和我一个班级的同学
    作者： 胡悦 2015-07-25
    参数：    studentId 学生Id
    返回值：存储结果的table
]]
local function getMyClassmates(self,studentId)
	local query_class_sql = "select class_id  from t_base_student where student_id = "..studentId;
	ngx.log(ngx.ERR, "[hy_log]->[person_info]-> 查询当前学生所在的班级的Sql语句 ===> [[["..query_class_sql.."]]]");
	local DBUtil      = require "common.DBUtil";
    local queryClassResult = DBUtil: querySingleSql(query_class_sql);
    if not queryClassResult then
        return false;
    end
	local calss_id;
	if queryClassResult and queryClassResult[1] then
		class_id = queryClassResult[1]["class_id"];
	else
		return false;
	end
	
	local query_student_sql = "select student_id from t_base_student where class_id = "..class_id.." and student_id<>"..studentId;
	local queryStudentResult = DBUtil: querySingleSql(query_student_sql);
	local resultTable = {};
    for index=1, #queryStudentResult do
        local record = queryStudentResult[index];
        table.insert(resultTable, { student_id=record["student_id"]} );
    end
    
    return resultTable;

end

_PersonInfoModel.getMyClassmates = getMyClassmates;
---------------------------------------------------------------------------

--[[
    描述： 根据老师ID获取我的学生
    作者： 胡悦 2015-07-25
    参数：    personId 教师Id
    返回值：存储结果的table
]]
local function getMyStudents(self,personId)
	local DBUtil      = require "common.DBUtil";
	local query_student_sql = "select t2.student_id from T_BASE_CLASS_SUBJECT t1  join  t_base_student t2 on t1.class_id = t2.class_id  where t1.teacher_id = 30317;";
	local queryStudentResult = DBUtil: querySingleSql(query_student_sql);
	local resultTable = {};
    for index=1, #queryStudentResult do
        local record = queryStudentResult[index];
        table.insert(resultTable, { student_id=record["student_id"]} );
    end
    
    return resultTable;

end

_PersonInfoModel.getMyStudents = getMyStudents;
---------------------------------------------------------------------------

--[[
    描述： 根据学生ID获取我的老师
    作者： 胡悦 2015-07-25
    参数：    studentId 学生ID
    返回值：存储结果的table
]]
local function getMyTeachers(self,studentId)
	local query_class_sql = "select class_id  from t_base_student where student_id = "..studentId;
	ngx.log(ngx.ERR, "[hy_log]->[person_info]-> 查询当前学生所在的班级的Sql语句 ===> [[["..query_class_sql.."]]]");
	local DBUtil      = require "common.DBUtil";
    local queryClassResult = DBUtil: querySingleSql(query_class_sql);
    if not queryClassResult or queryClassResult[1]==nil then
        return false;
    end
	local calss_id;
	if queryClassResult and queryClassResult[1] then
		class_id = queryClassResult[1]["class_id"];
	else
		return false;
	end
	local query_teacher_sql = "select distinct teacher_id from T_BASE_CLASS_SUBJECT where class_id = "..class_id;
	local queryTeacherResult = DBUtil: querySingleSql(query_teacher_sql);
	local resultTable = {};
    for index=1, #queryTeacherResult do
        local record = queryTeacherResult[index];
        table.insert(resultTable, { teacher_id=record["teacher_id"]} );
    end
    
    return resultTable;

end

_PersonInfoModel.getMyTeachers = getMyTeachers;
---------------------------------------------------------------------------
--[[
    描述： 获取人员信息
	根据person_id和identity_id查询用户详细信息，
	1.如果是教师返回登录名login_name、真实姓名、所属省、市、区、校id及名称，2如果是学生还要增加返回班级id及班级名称
]]
local function getPersonInfo(self,person_id,identity_id)
		local resultTable = {};
		local _CacheUtil = require "common.CacheUtil";
		local DBUtil  = require "common.DBUtil";
		local cache = _CacheUtil.getRedisConn();
		local user_cache =_CacheUtil:hmget("person_"..person_id.."_"..identity_id,"person_name","sheng","shi","qu","xiao");
		local person_name = user_cache["person_name"];
		if person_name == nil or person_name == ""  or person_name == ngx.null  then 
			
			return false;
		end
		
		local province_id = user_cache["sheng"];
		local city_id = user_cache["shi"];
		local district_id = user_cache["qu"];
		
		local bureau_id =  user_cache["xiao"];--单位ID 
		local bureau_type;                    --单位类型 1为教育局 2学校 3部门
		
		local query_bureau_type_sql="select org_type from t_base_organization where org_id="..bureau_id;
		ngx.log(ngx.ERR,"查询单位类型的SQL："..query_bureau_type_sql);
		
		local query_bureau_type_res = DBUtil: querySingleSql(query_bureau_type_sql);
		
		bureau_type=query_bureau_type_res[1]["org_type"];
		
		
		resultTable["bureau_id"] = bureau_id;
		resultTable["bureau_type"] = bureau_type;
		resultTable["person_name"] = person_name;
		resultTable["province_id"] = province_id;
		resultTable["city_id"] = city_id;
		resultTable["district_id"] = district_id;
		local org_cache = _CacheUtil:hmget("t_base_organization_"..bureau_id,"org_name");
		resultTable["bureau_name"] = org_cache["org_name"];
		if tonumber(bureau_type) == 2 then 
			local school_id = user_cache["xiao"];
			resultTable["school_id"] = school_id;
			resultTable["school_name"] = org_cache["org_name"];
			--查询分校信息 
			local query_branch_school_sql = "select org_id as school_id,org_name as school_name from t_base_organization where main_school_id="..school_id;
			ngx.log(ngx.ERR,"查询分校信息SQL---->"..query_branch_school_sql);
			local query_branch_school_res = DBUtil: querySingleSql(query_branch_school_sql);
			resultTable["branch_school"]=query_branch_school_res;
			
			--查询主校信息
			local query_main_school_sql="select t1.org_id,t1.org_name from t_base_organization t1 inner join t_base_organization t2 on t1.org_id = t2.main_school_id where t2.org_id = "..school_id;
			local query_main_school_res = DBUtil: querySingleSql(query_main_school_sql);
			if query_main_school_res and query_main_school_res[1] then 
				resultTable["main_school_id"]=query_main_school_res[1]["org_id"];
				resultTable["main_school_name"]=query_main_school_res[1]["org_name"];
			else
				resultTable["main_school_id"]="";
				resultTable["main_school_name"]="";
			end
		end
		
		local query_province_sql = "select provincename from t_gov_province where id = "..province_id;
		local query_city_sql="select cityname from t_gov_city where id = "..city_id;
		local query_district_sql="select districtname from t_gov_district where id="..district_id;
		local queryProvinceResult= DBUtil: querySingleSql(query_province_sql);
		if queryProvinceResult and queryProvinceResult[1] then
				resultTable["province_name"] = queryProvinceResult[1]["provincename"];
			else
				resultTable["province_name"] = "";
		end
		local queryCityResult= DBUtil: querySingleSql(query_city_sql);
		if queryCityResult and queryCityResult[1] then
				resultTable["city_name"] = queryCityResult[1]["cityname"];
			else
				resultTable["city_name"] = "";
		end
		
		local queryDistrictResult= DBUtil: querySingleSql(query_district_sql);
		if queryDistrictResult and queryDistrictResult[1] then
				resultTable["district_name"] = queryDistrictResult[1]["districtname"];
			else
				resultTable["district_name"] = "";
		end
		
		
		if tonumber(identity_id) == 6 then
		--学生
			local query_class_sql = "select c.class_id,c.class_name from t_base_student s  join t_base_class c  on s.class_id = c.class_id  where student_id ="..person_id;
			ngx.log(ngx.ERR, "[hy_log]->[person_info]-> 查询学生所在班级 ===> [[["..query_class_sql.."]]]");
		
			local queryClassResult = DBUtil: querySingleSql(query_class_sql);
			if queryClassResult and queryClassResult[1] then
				resultTable["class_id"] = queryClassResult[1]["class_id"];
				resultTable["class_name"] = queryClassResult[1]["class_name"];
			else
				return false;
			end
			
		end
		--查询角色 
		local query_role_sql="select distinct pr.role_id,r.role_code,r.role_name from t_sys_person_role pr join t_sys_role r on pr.role_id=r.role_id where pr.person_id="..person_id.." and pr.identity_id="..identity_id;
		ngx.log(ngx.ERR,"查询角色的SQL---->"..query_role_sql);
		
		local query_role_res=DBUtil: querySingleSql(query_role_sql);
		resultTable["roles"]=query_role_res;
		
		local query_login_sql="select login_name from t_sys_loginperson where person_id="..person_id.." and identity_id="..identity_id;
		local query_login_res = DBUtil: querySingleSql(query_login_sql);
		
		if query_login_res==nil or query_login_res[1]==nil or query_login_res[1]["login_name"] == ngx.null then
				resultTable["login_name"]="";
		else 
				resultTable["login_name"]=query_login_res[1]["login_name"];
		end
			
		_CacheUtil:keepConnAlive(cache)
		
		return resultTable;

end
_PersonInfoModel.getPersonInfo = getPersonInfo;

---------------------------------------------------------------------------
--[[
    描述： 根据学校ID获取所有教师
]]
local function getTeachersBySchId(self,school_id)
	local DBUtil      = require "common.DBUtil";
	local cjson = require "cjson"
	local query_sql = "select person_id,person_name from t_base_person where identity_id = 5 and bureau_id ="..school_id;
	ngx.log(ngx.ERR,"查询学校下的老师的SQL--->"..query_sql);
	local queryResult= DBUtil: querySingleSql(query_sql);
	local returnResult={};
	if not queryResult then
        return returnResult;
    end
	for i=1,#queryResult do
		local res = {}
		local person_id = queryResult[i]["person_id"]
		local person_name = queryResult[i]["person_name"]
		res.person_id = person_id;
		res.person_name = person_name;
		ngx.log(ngx.ERR,"person_id:"..person_id..",person_name:"..person_name);
		local value = ngx.location.capture("/dsideal_yy/person/getPersonTxByYw?person_id="..person_id.."&identity_id=5&yw=ypt")
		local result = cjson.decode(value.body);
		--ngx.log(ngx.ERR,result.file_id);
		--{"file_id":"A40F8EF0-92FE-2E68-0E8D-34CB5D22F1D9","extension":"png","success":true}
		if result.success then
			res.file_id = result.file_id
			res.extension=result.extension
		end
		
		returnResult[i]= res;
	end
	
	return returnResult;

end
_PersonInfoModel.getTeachersBySchId = getTeachersBySchId;
-- -------------------------------------------------------------------------

--[[
	局部函数：在指定单位下根据用户名模糊查询用户包含教师和学生
	作者： 胡悦 2015-08-27
	参数：unitId  单位ID
]]
local function queryPersonsByKeyAndOrg(self, unitId, personNameKey, pageNumber, pageSize)
	
	local DBUtil = require "common.DBUtil";
	
	local queryKey = ngx.quote_sql_str("%" .. personNameKey .. "%");
	
	local fieldTab = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "BUREAU_ID", "BUREAU_ID"};
	local fieldTab_name = {"PROVINCE_NAME", "CITY_NAME", "DISTRICT_NAME", "SCHOOL_NAME", "ORG_NAME"};
	local CheckPerson = require "multi_check.model.CheckPerson";
	local unitType = CheckPerson:getUnitType(unitId);
	ngx.log(ngx.ERR, "[hy_log] -> [person_info] -> 单位类型(unitType)：[" .. unitType .. "]");
	ngx.log(ngx.ERR, "===> 参数：personNameKey -> [", personNameKey, "]");
	local fieldName = fieldTab[unitType];
	
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM (".. 
				 " select PERSON_ID, JP,QP,PERSON_NAME,IDENTITY_ID,ORG_ID,BUREAU_ID,PROVINCE_ID,CITY_ID,DISTRICT_ID from T_BASE_PERSON  union all".. 
				 " select S.STUDENT_ID as PERSON_ID,S.JP,S.QP,S.STUDENT_NAME AS PERSON_NAME,6 as IDENTITY_ID, C.ORG_ID,S.BUREAU_ID,O.PROVINCE_ID,O.CITY_ID,O.DISTRICT_ID"..
				 " from T_BASE_STUDENT S  JOIN T_BASE_CLASS C  ON S.CLASS_ID=C.CLASS_ID join T_BASE_ORGANIZATION O ON C.ORG_ID=O.ORG_ID ) PERSON".. 
				" INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID "..
				" INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID "..
				" INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID "..
				" INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID "..
				" INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID "..
				" WHERE PERSON." .. fieldName .. "=" .. unitId .. " AND (PERSON.QP LIKE " .. queryKey .. " OR PERSON.JP LIKE " .. queryKey .. " OR PERSON.PERSON_NAME LIKE " .. queryKey .. ") AND (PERSON.IDENTITY_ID=5 or PERSON.IDENTITY_ID=6)  ";
	ngx.log(ngx.ERR, " ===> countSql语句 ===> ", countSql);
	local res=DBUtil: querySingleSql(countSql);
	
	local totalRow = res[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset = pageSize*pageNumber-pageSize;
	local limit  = pageSize;
	

	local sql = "SELECT PERSON.PERSON_ID, PERSON.IDENTITY_ID, PERSON.PERSON_NAME,"..
				" PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME,"..
				" CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME,".. 
				" DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME,"..
				" SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME,"..
				" ORG.ORG_ID, ORG.ORG_NAME FROM (".. 
				 " select PERSON_ID, JP,QP,PERSON_NAME,IDENTITY_ID,ORG_ID,BUREAU_ID,PROVINCE_ID,CITY_ID,DISTRICT_ID from T_BASE_PERSON  union all".. 
				 " select S.STUDENT_ID as PERSON_ID,S.JP,S.QP,S.STUDENT_NAME AS PERSON_NAME,6 as IDENTITY_ID, C.ORG_ID,S.BUREAU_ID,O.PROVINCE_ID,O.CITY_ID,O.DISTRICT_ID"..
				 " from T_BASE_STUDENT S  JOIN T_BASE_CLASS C  ON S.CLASS_ID=C.CLASS_ID join T_BASE_ORGANIZATION O ON C.ORG_ID=O.ORG_ID ) PERSON".. 
				" INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID".. 
				" INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID".. 
				" INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID".. 
				" INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID".. 
				" INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID".. 
				" WHERE PERSON." .. fieldName .. "=" .. unitId .. " AND (PERSON.QP LIKE " .. queryKey .. " OR PERSON.JP LIKE " .. queryKey .. " OR PERSON.PERSON_NAME LIKE " .. queryKey .. ") AND (PERSON.IDENTITY_ID=5 or PERSON.IDENTITY_ID=6)  LIMIT " .. offset .. "," .. limit;
	ngx.log(ngx.ERR, " ===> sql语句 ===> ", sql);

	local res=DBUtil: querySingleSql(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local resultListObj = {};
	for i=1, #res do
		local record = {};
		record.person_id   	 = res[i]["PERSON_ID"];
		record.identity_id   = res[i]["IDENTITY_ID"];
		record.person_name   = res[i]["PERSON_NAME"];
		record.unit_type	 = unitType;
		record.province_id 	 = res[i]["PROVINCE_ID"];
		record.province_name = res[i]["PROVINCE_NAME"];
		record.city_id 		 = res[i]["CITY_ID"];
		record.city_name 	 = res[i]["CITY_NAME"];
		record.district_id 	 = res[i]["DISTRICT_ID"];
		record.district_name = res[i]["DISTRICT_NAME"];
		record.school_id 	 = res[i]["SCHOOL_ID"];
		record.sch_name 	 = res[i]["SCHOOL_NAME"];
		record.org_id 		 = res[i]["ORG_ID"];
		record.org_name 	 = res[i]["ORG_NAME"];
	--[[
		if res[i]["STAGE_ID"] == ngx.null or res[i]["STAGE_ID"] == nil or res[i]["STAGE_ID"]=="" or res[i]["STAGE_NAME"] == ngx.null or res[i]["SUBJECT_ID"] == ngx.null or res[i]["SUBJECT_NAME"] == ngx.null then
			record.stage_id 	= 0;
			record.subject_id 	= 0;
			record.subject_name = "--";
		else
			record.stage_id 	= res[i]["STAGE_ID"];
			record.subject_id 	= res[i]["SUBJECT_ID"];
			record.subject_name = res[i]["STAGE_NAME"] .. res[i]["SUBJECT_NAME"];
		end
]]			
		local school_name = "";
		for j = unitType + 1, #fieldTab do
			if j == unitType + 1 then
				school_name = res[i][fieldTab_name[j]];
			else
				school_name = school_name .. "--" .. res[i][fieldTab_name[j]];
			end
		end
		record.school_name = school_name;
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success   = true;
	resultJsonObj.records   = totalRow;
	resultJsonObj.total 	= totalPage;
	resultJsonObj.page 		= pageNumber;
	resultJsonObj.rows 		= resultListObj;
	

	
	return resultJsonObj;
end

_PersonInfoModel.queryPersonsByKeyAndOrg = queryPersonsByKeyAndOrg;
---------------------------------------------------------------------------
return _PersonInfoModel;