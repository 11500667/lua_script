--[[
	申健 	2015-04-24
	描述： 	学生信息基础接口
]]
local _StudentModel = {};



-- -------------------------------------------------------------------------
--[[
	描述：	根据学生ID获取指定的学生信息
	参数：	studentId 	 	学生ID
]]
local function getById(self, studentId)
	local sql = "SELECT STUDENT_ID, STUDENT_NAME, XB_NAME, BIRTHDAY, CREATE_TIME, B_USE, BUREAU_ID, CLASS_ID, AVATAR_NAME, EMAIL, CHECK_STATE, CHECK_MESSAGE, AVATAR_URL, MOTTO, PAR_TEL, STU_TEL FROM T_BASE_STUDENT WHERE STUDENT_ID=" .. studentId .. ";";
	
	local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(sql);

    if not queryResult then
        return false;
    end
    return queryResult[1];
end

_StudentModel.getById = getById;

-- -------------------------------------------------------------------------
--[[
	描述：	根据班级ID获取学生信息
	参数：	classId 	 	学生ID
]]
local function getStudentByClassIds(self, classIds)
    local sql = "SELECT STUDENT_ID,CLASS_ID,BUREAU_ID from t_base_student  where B_USE=1 and CLASS_ID in (" .. classIds .. ");";

    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil:querySingleSql(sql);
    if not queryResult then
        return {};
    end
    return queryResult;
end

_StudentModel.getStudentByClassIds = getStudentByClassIds;

-- -------------------------------------------------------------------------
--[[
    描述： 根据学生ID获取指定的学生信息
    参数： studentId       学生ID
    参数： identityId      身份ID
]]
local function getByIdAndIdentity(self, studentId, identityId)
    local CacheUtil = require "common.CacheUtil";
    local cache = CacheUtil: getRedisConn();
    --ngx.log(ngx.ERR, "===> 获取学生所在的班级 <=== ");
    local result, err = cache: hget("person_" .. studentId .. "_" .. identityId, "class_name");
    --ngx.log(ngx.ERR, "===> 从缓存中查询的结果 <=== ", result);
    
    local record = {};
    if result == ngx.null then
        ngx.log(ngx.ERR, "===> 缓存中没有取到学生所在的班级名-> [没有] <=== ");
        local querySql = "SELECT T2.CLASS_ID, T2.CLASS_NAME FROM T_BASE_STUDENT T1 INNER JOIN T_BASE_CLASS T2 ON T1.CLASS_ID=T2.CLASS_ID WHERE T1.STUDENT_ID=" .. studentId;
        local DBUtil = require "common.DBUtil";
        local queryResult = DBUtil: querySingleSql(querySql);

        if not queryResult then
            CacheUtil: keepConnAlive(cache);
            return false;
        end
        local className   = queryResult[1]["CLASS_NAME"];
        cache: hset("person_" .. studentId .. "_" .. identityId, "class_name", queryResult[1]["CLASS_NAME"]);
        record.class_name = className;
    else
        ngx.log(ngx.ERR, "===> 缓存中取到学生所在的班级名-> [有] <=== ");
        record.class_name  = result;
    end
 
    CacheUtil: keepConnAlive(cache);
    return record;
end

_StudentModel.getByIdAndIdentity = getByIdAndIdentity;

-- -------------------------------------------------------------------------
--[[
	局部函数：根据多个ID获取学生
	参数：	studentIds 	 多个学生的ID
	返回值：	table对象，存储多个学生的ID
]]
local function getByIds(self, studentIds)
	
	local DBUtil = require "common.DBUtil";
	local querySql = "SELECT STUDENT.STUDENT_ID, STUDENT.STUDENT_NAME, CLASS.CLASS_ID, CLASS.CLASS_NAME, CLASS.STAGE_ID AS CLASS_TYPE, SCHOOL.ORG_ID, SCHOOL.ORG_NAME, SCHOOL.PROVINCE_ID, SCHOOL.CITY_ID, SCHOOL.DISTRICT_ID "; 
	local whereSql = "FROM T_BASE_STUDENT STUDENT " .. 
	"INNER JOIN T_BASE_CLASS CLASS ON STUDENT.CLASS_ID=CLASS.CLASS_ID " .. 
	"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON CLASS.BUREAU_ID=SCHOOL.ORG_ID WHERE STUDENT.B_USE=1 ";
    
	if studentIds ~= nil and #studentIds > 0 then
		for index = 1, #studentIds do
            local studentId = studentIds[index];
            if index == 1 then
                whereSql = whereSql .. " AND (STUDENT.STUDENT_ID=" .. studentId;
            else
                whereSql = whereSql .. " OR STUDENT.STUDENT_ID=" .. studentId;
            end

            if index == #studentIds then
                whereSql = whereSql .. ") ";
            end
		end
    else
        return {};
    end

    querySql = querySql .. whereSql;
	ngx.log(ngx.ERR, "===> 根据多个ID查询学生的sql语句 ===> ", querySql);
    local queryResult = DBUtil: querySingleSql(querySql);
	if not queryResult then
		return false;
	end

	local stuList = {};
	for index = 1, #queryResult do
		local stuRecord = queryResult[index];
		local convertRecord = {};

		convertRecord["student_id"]   = stuRecord["STUDENT_ID"];
		convertRecord["student_name"] = stuRecord["STUDENT_NAME"];
		convertRecord["school_id"]    = tonumber(stuRecord["ORG_ID"]);
		convertRecord["school_name"]  = stuRecord["ORG_NAME"];
		convertRecord["class_id"]     = stuRecord["CLASS_ID"];
		convertRecord["class_name"]   = stuRecord["CLASS_NAME"];
		convertRecord["class_type"]   = stuRecord["STAGE_ID"];
		convertRecord["province_id"]  = stuRecord["PROVINCE_ID"];
		convertRecord["city_id"]      = stuRecord["CITY_ID"];
		convertRecord["district_id"]  = stuRecord["DISTRICT_ID"];

		table.insert(stuList, convertRecord);
	end
    return stuList;
end

_StudentModel.getByIds = getByIds;
-- -------------------------------------------------------------------------

return _StudentModel;