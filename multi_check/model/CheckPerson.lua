--[[
#申健 2015-03-08
#描述：审核人员设置的基础函数类
]]

local _CheckPerson = { author="shenjian"};

---------------------------------------------------------------------------
--[[
	局部函数：判断该单位是否已经将指定的教师设置为审核人员
	作者： 申健 2015-03-08
	参数：unitId  		单位ID
	参数：personId  	被设置的教师人员ID
	参数：identityId  	被设置的教师的身份ID
	参数：subjectId  	科目ID
	返回值：isPersonExist 该教师是否为该单位的审核人员：0不是，1是（不考虑设置的科目）
	返回值：isPersonSubjectExist 该教师是否为该单位下指定科目的审核人员：0不是，1是
]]
local function isCheckPersonExist(self, unitId, personId, identityId, subjectId)
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	local isPersonExist = false;
	local isPersonSubjectExist = false;
	
	local sql = "SELECT T1.UNIT_ID, T1.PERSON_ID, T2.SUBJECT_ID FROM T_BASE_CHECK_PERSON T1 LEFT OUTER JOIN T_BASE_CHECK_PERSON_SUBJECT T2 ON T1.UNIT_ID=T2.UNIT_ID AND T1.PERSON_ID=T2.PERSON_ID AND T1.IDENTITY_ID=T2.IDENTITY_ID AND T2.SUBJECT_ID=" .. subjectId .. " WHERE T1.UNIT_ID=" .. unitId .. " AND T1.PERSON_ID=" .. personId .. " AND T1.IDENTITY_ID=" .. identityId;
	
	ngx.log(ngx.ERR, "===> sql 语句 ===> type: ", sql);
	
	local result, err, errno, sqlstate = db:query(sql);
	local cjson = require "cjson";
	ngx.log(ngx.ERR, "===> isCheckPersonExist函数中 result ===> type: ", type(result), ", ===> value : ", cjson.encode(result));

	if not result or #result==0 then
		return isPersonExist, isPersonSubjectExist;
	end
	
	local personInfo = result[1];
	if personInfo["PERSON_ID"] ~= nil then
		isPersonExist = true;
	end
	
	if personInfo["SUBJECT_ID"] ~= ngx.null then
		isPersonSubjectExist = true;
	end
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return isPersonExist, isPersonSubjectExist;
end
-- ***注意：声明对象的内部函数时，如果用.的形式，则函数的第一个参数必须为self，其他参数依次顺延
-- 如果用:的形式，则不需要定义self这个参数
-- 在调用函数的时候也是如此；
_CheckPerson.isCheckPersonExist = isCheckPersonExist;

---------------------------------------------------------------------------------
--[[
	局部函数：根据单位ID获取单位类型
	作者： 申健 2015-03-08
	参数：unitId  单位ID
]]
local function getUnitType(self, unitId)
	local unitType;
	if unitId > 100000 and unitId < 200000 then
		unitType = 1;
	elseif unitId > 200000 and unitId < 300000 then
		unitType = 2;
	elseif unitId > 300000 and unitId < 400000 then
		unitType = 3;
	else
		unitType = 4;
	end
	return unitType;
end

_CheckPerson.getUnitType = getUnitType;

---------------------------------------------------------------------------
--[[
	局部函数：获取指定单位设置的审核人员
	作者： 申健 2015-03-08
	参数：unitId  单位ID
]]
local function getCheckPersonByUnitId(self, unitId, stageId, subjectId, personName, unitArray,  pageNumber, pageSize)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();

	local conditionSegment = "FROM T_BASE_CHECK_PERSON CP INNER JOIN T_BASE_CHECK_PERSON_SUBJECT CPS ON CP.UNIT_ID=CPS.UNIT_ID AND CP.PERSON_ID=CPS.PERSON_ID AND CP.IDENTITY_ID=CPS.IDENTITY_ID INNER JOIN T_BASE_PERSON P ON CP.PERSON_ID = P.PERSON_ID AND CP.IDENTITY_ID=P.IDENTITY_ID WHERE CP.UNIT_ID=" .. unitId;

	if subjectId ~= nil and subjectId ~= 0 then
		conditionSegment = conditionSegment .. " AND CPS.SUBJECT_ID = " .. subjectId;
	elseif stageId ~= nil and stageId ~= 0 then
		conditionSegment = conditionSegment .. " AND CPS.STAGE_ID = " .. stageId;
	end

	if personName ~= nil and personName ~= "" then
		conditionSegment = conditionSegment .. " AND P.PERSON_NAME LIKE " .. ngx.quote_sql_str("%" .. personName .. "%");
	end

	if unitArray ~= nil and #unitArray > 0 then
		local fieldTable =  { "PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "BUREAU_ID" };
		conditionSegment = conditionSegment .. " AND ( 1=2 ";
		for index, record in ipairs(unitArray) do
			local chkUnitType = tonumber(record["unit_type"]);
			local chkUnitId   = record["unit_id"];

			conditionSegment = conditionSegment .. " OR " .. fieldTable[chkUnitType] .. "=" .. chkUnitId;
		end
		conditionSegment = conditionSegment .. " )";
	end
	
	-- 查询符合记录的总数
	local countSql = "SELECT COUNT(DISTINCT CP.PERSON_ID) AS TOTAL_ROW " .. conditionSegment;
	
	local res, err, errno, sqlstate = db:query(countSql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	local totalRow  = res[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize);
	local offset    = pageSize * pageNumber - pageSize;
	local limit     = pageSize;
	
	local querySql = "SELECT DISTINCT CP.UNIT_ID, CP.UNIT_NAME, CP.PERSON_ID, CP.PERSON_NAME, CP.IDENTITY_ID, CP.PROVINCE_NAME, CP.CITY_NAME, CP.DISTRICT_NAME, CP.SCHOOL_NAME, CP.ORG_NAME " .. conditionSegment .. " ORDER BY SET_TIME DESC LIMIT " .. offset .. "," .. limit;
	ngx.log(ngx.ERR, "====> sql ===> " .. querySql);

	local res, err, errno, sqlstate = db:query(querySql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local resultListObj = {};
	for i=1, #res do
		local record = {};
		record.UNIT_ID 	  		= res[i]["UNIT_ID"];
		record.UNIT_NAME   		= res[i]["UNIT_NAME"];
		record.PERSON_ID   		= res[i]["PERSON_ID"];
		record.PERSON_NAME 		= res[i]["PERSON_NAME"];
		record.IDENTITY_ID   	= res[i]["IDENTITY_ID"];
		record.PROVINCE_NAME 	= res[i]["PROVINCE_NAME"];
		record.CITY_NAME 		= res[i]["CITY_NAME"];
		record.DISTRICT_NAME 	= res[i]["DISTRICT_NAME"];
		record.SCHOOL_NAME 		= res[i]["SCHOOL_NAME"];
		record.ORG_NAME 		= res[i]["ORG_NAME"];
		
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success    = true;
	resultJsonObj.totalRow   = totalRow;
	resultJsonObj.totalPage  = totalPage;
	resultJsonObj.pageNumber = pageNumber;
	resultJsonObj.pageSize   = pageSize;
	resultJsonObj.table_List = resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return resultJsonObj;
end

_CheckPerson.getCheckPersonByUnitId = getCheckPersonByUnitId;


---------------------------------------------------------------------------

local function _getDelPersonSql(unitId, personId, identityId)
	local sql = "DELETE FROM T_BASE_CHECK_PERSON WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
	return sql;
end

---------------------------------------------------------------------------

local function _getDelAllPersonSubjectSql(unitId, personId, identityId)
	local sql = "DELETE FROM T_BASE_CHECK_PERSON_SUBJECT WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
	return sql;
end

---------------------------------------------------------------------------

local function _getDelPersonSubjectSql(unitId, personId, identityId, subjectId)
	local sql = "DELETE FROM T_BASE_CHECK_PERSON_SUBJECT WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " AND SUBJECT_ID=" .. subjectId .. ";"
	return sql;
end




---------------------------------------------------------------------------
--[[
	局部函数：获取指定单位设置的审核人员
	作者： 申健 2015-03-08
	参数：unitId  单位ID
]]
local function delCheckPerson(self, unitId, delPerArray)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	-- sqlTab 用于保存需要批量执行的sql语句
	local sqlTab = {};
	for i=1, #delPerArray do
		local personId 	 = delPerArray[i]["person_id"];
		local identityId = delPerArray[i]["identity_id"];
		-- 删除审核人员
		deleteSql = _getDelPersonSql(unitId, personId, identityId)
		table.insert(sqlTab, deleteSql);
		-- 删除审核人员和科目的关联关系
		deleteSql = _getDelAllPersonSubjectSql(unitId, personId, identityId);
		table.insert(sqlTab, deleteSql);
	end
	
	local result = DBUtil:batchExecuteSqlInTx(sqlTab, 50);
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return result;
end

_CheckPerson.delCheckPerson = delCheckPerson;

---------------------------------------------------------------------------
--[[
	局部函数：判断该教师在指定单位下可审核的科目
	作者： 申健 2015-03-09
	参数：unitId  		单位ID
	参数：personId  	被设置的教师人员ID
	参数：identityId  	被设置的教师的身份ID
	返回值：resultJsonObj 科目列表
]]
local function getSubjectByPerson(self, unitId, personId, identityId)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	-- 获取审核人员在指定单位下的权限[资源审核]、[设置审核人员]
	local sql = "SELECT ALLOW_ADD_PERSON, ALLOW_CHECK FROM T_BASE_CHECK_PERSON WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId;
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local allowAddPerson = 0;
	local allowCheck	 = 0;
	if #res > 0 then 
		allowAddPerson 	= res[1]["ALLOW_ADD_PERSON"];
		allowCheck	 	= res[1]["ALLOW_CHECK"];
	end
	
	-- 获取审核人员在指定单位下的可以审核的学科
	sql = "SELECT UNIT_ID, PERSON_ID, IDENTITY_ID, STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME FROM T_BASE_CHECK_PERSON_SUBJECT WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " ORDER BY STAGE_ID DESC;";
	
	ngx.log(ngx.ERR, "===> 查询教师在指定单位可审核的科目， sql语句：[", sql, "]");
	
	res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local resultListObj = {};
	for i=1, #res do
		local record = {};
		record.STAGE_ID  		= res[i]["STAGE_ID"];
		record.STAGE_NAME 		= res[i]["STAGE_NAME"];
		record.SUBJECT_ID		= res[i]["SUBJECT_ID"];
		record.SUBJECT_NAME		= res[i]["SUBJECT_NAME"];
		
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success    		= true;
	resultJsonObj.allow_add_person 	= allowAddPerson;
	resultJsonObj.allow_check		= allowCheck;
	resultJsonObj.subject_List 		= resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return resultJsonObj;
end

_CheckPerson.getSubjectByPerson = getSubjectByPerson;

---------------------------------------------------------------------------
--[[
	局部函数：获取该教师可以审核的单位
	作者： 申健 2015-03-09
	参数： personId  		被设置的教师人员ID
	参数： identityId  		被设置的教师的身份ID
	参数： authType  		权限类型：1资源审核，2设置审核人员
	返回值：resultJsonObj 	单位列表
]]
local function getUnitByPerson(self, personId, identityId, authType)

	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	
	local resultListObj = {};
	if authType == 1 then -- 获取教师可以审核的地区列表
		local sql = "SELECT T1.UNIT_ID, T1.UNIT_NAME FROM T_BASE_CHECK_PERSON T1 WHERE T1.PERSON_ID=" .. personId .. " AND T1.IDENTITY_ID=" .. identityId .. " AND T1.ALLOW_CHECK=1;";
		
		ngx.log(ngx.ERR, "===> 查询教师可审核资源的单位和科目， sql语句：[", sql, "]");
		
		local res, err, errno, sqlstate = db:query(sql);
		if not res then
			return {success=false, info="查询数据出错！"};
		end
		
		for i=1, #res do
			local record = {};
			record.UNIT_ID   = tonumber(res[i]["UNIT_ID"]);
			record.UNIT_NAME = res[i]["UNIT_NAME"];
			record.UNIT_TYPE = self: getUnitType(record.UNIT_ID);
			table.insert(resultListObj, record);
		end
	elseif authType == 2 then -- 获取可设置审核人员的地区列表
	
		local sql = "SELECT UNIT_ID, UNIT_NAME, PERSON_ID, PERSON_NAME, IDENTITY_ID FROM T_BASE_CHECK_PERSON WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " AND ALLOW_ADD_PERSON=1;";
		ngx.log(ngx.ERR, "===> 查询教师可设置审核人员的单位， sql语句：[", sql, "]");
		
		local res, err, errno, sqlstate = db:query(sql);
		if not res then
			return {success=false, info="查询数据出错！"};
		end
		
		for i=1, #res do
			local record = {};
			record.UNIT_ID  		= res[i]["UNIT_ID"];
			record.UNIT_NAME 		= res[i]["UNIT_NAME"];			
			record.UNIT_TYPE = self: getUnitType(record.UNIT_ID);
			
			table.insert(resultListObj, record);
		end
		
	end
	
	local resultJsonObj = {};
	resultJsonObj.success    = true;
	resultJsonObj.unit_list = resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return resultJsonObj;

end

_CheckPerson.getUnitByPerson = getUnitByPerson;

---------------------------------------------------------------------------
--[[
	局部函数：获取该教师是否为审核人员
	作者： 申健 2015-03-09
	参数： personId  		被设置的教师人员ID
	参数： identityId  		被设置的教师的身份ID
	返回值：boolean      	true是审核人员，false不是审核人员
]]
local function isCheckPerson(self, personId, identityId)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	ngx.log(ngx.ERR, "===> 获取教师的权限 ===> 人员ID：[", personId, "], 身份ID：[", identityId, "]");
	
	local sql = "SELECT IFNULL(SUM(ALLOW_CHECK), 0) AS ALLOW_CHECK, IFNULL(SUM(ALLOW_ADD_PERSON), 0) AS ALLOW_ADD_PERSON FROM T_BASE_CHECK_PERSON WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId;
	
	ngx.log(ngx.ERR, "===> 获取教师的权限 ===> SQL语句：[", sql, "]");
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local allowAddPerson = false;
	local allowCheck	 = false;
	
	if #res > 0 then
		allowCheck     = tonumber(res[1]["ALLOW_CHECK"])>0;
		allowAddPerson = tonumber(res[1]["ALLOW_ADD_PERSON"])>0;
	end
	
	ngx.log(ngx.ERR, "===> 是否允许审核资源：["	, ((allowCheck and "允许") or "不允许"), "]");
	ngx.log(ngx.ERR, "===> 是否允许添加审核人员：[", ((allowAddPerson and "允许") or "不允许"), "]");
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return allowCheck, allowAddPerson;
	
end

_CheckPerson.isCheckPerson = isCheckPerson;

---------------------------------------------------------------------------
--[[
	局部函数：（开平专用，稍后删除）获取该教师是否为区级审核人员
	作者： 	申健 2015-04-02
	参数： 	personId  		被设置的教师人员ID
	参数： 	identityId  	被设置的教师的身份ID
	返回值：boolean      	true是区级审核人员，false不是区级审核人员
]]
local function isDistrictCheckPerson(self, personId, identityId)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	ngx.log(ngx.ERR, "===> 获取教师的权限 ===> 人员ID：[", personId, "], 身份ID：[", identityId, "]");
	
	local sql = "SELECT COUNT(1) AS REC_COUNT FROM T_BASE_CHECK_PERSON WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " AND ALLOW_CHECK=1 AND UNIT_ID BETWEEN 300000 AND 400000;";
	
	ngx.log(ngx.ERR, "===> 获取教师的权限 ===> SQL语句：[", sql, "]");
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local isDistrictCheckPer = false;
	
	if #res > 0 then
		isDistrictCheckPer    = tonumber(res[1]["REC_COUNT"])>0;
	end
	
	ngx.log(ngx.ERR, "===> 是否区的审核人员：["	, ((booleanFlag and "是") or "否"), "]");
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return isDistrictCheckPer;
	
end

_CheckPerson.isDistrictCheckPerson = isDistrictCheckPerson;

---------------------------------------------------------------------------
--[[
	局部函数：在指定单位下根据用户名模糊查询用户
	作者： 申健 2015-03-10
	参数：unitId  单位ID
]]
local function queryPersonByKeyAndOrg(self, unitId, personNameKey, pageNumber, pageSize)
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	local queryKey = ngx.quote_sql_str("%" .. personNameKey .. "%");
	
	local fieldTab = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "BUREAU_ID", "BUREAU_ID"};
	local fieldTab_name = {"PROVINCE_NAME", "CITY_NAME", "DISTRICT_NAME", "SCHOOL_NAME", "ORG_NAME"};
	local unitType = getUnitType(self, unitId);
	ngx.log(ngx.ERR, "[sj_log] -> [person_info] -> 单位类型(unitType)：[" .. unitType .. "]");
	ngx.log(ngx.ERR, "===> 参数：personNameKey -> [", personNameKey, "]");
	local fieldName = fieldTab[unitType];
	
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_PERSON PERSON "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID "..
				"INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID "..
				"WHERE PERSON." .. fieldName .. "=" .. unitId .. " AND (PERSON.QP LIKE " .. queryKey .. " OR PERSON.JP LIKE " .. queryKey .. " OR PERSON.PERSON_NAME LIKE " .. queryKey .. ") AND PERSON.IDENTITY_ID=5";

	ngx.log(ngx.ERR, " ===> countSql语句 ===> ", countSql);
	local res, err, errno, sqlstate = db:query(countSql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	local totalRow = res[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset = pageSize*pageNumber-pageSize;
	local limit  = pageSize;
	
	

	local sql = "SELECT PERSON.PERSON_ID, PERSON.IDENTITY_ID, PERSON.PERSON_NAME, "..
				"PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME, "..
				"CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME, "..
				"DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME, "..
				"SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME, "..
				"ORG.ORG_ID, ORG.ORG_NAME, "..
				"PERSON.STAGE_ID, PERSON.STAGE_NAME, PERSON.SUBJECT_ID, PERSON.SUBJECT_NAME " ..
				"FROM T_BASE_PERSON PERSON "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID "..
				"INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID "..
				"WHERE PERSON." .. fieldName .. "=" .. unitId .. " AND (PERSON.QP LIKE " .. queryKey .. " OR PERSON.JP LIKE " .. queryKey .. " OR PERSON.PERSON_NAME LIKE " .. queryKey .. ") AND PERSON.IDENTITY_ID=5 LIMIT " .. offset .. "," .. limit;
	ngx.log(ngx.ERR, " ===> sql语句 ===> ", sql);

	local res, err, errno, sqlstate = db:query(sql);
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
		
		if res[i]["STAGE_ID"] == ngx.null or res[i]["STAGE_ID"] == nil or res[i]["STAGE_ID"]=="" or res[i]["STAGE_NAME"] == ngx.null or res[i]["SUBJECT_ID"] == ngx.null or res[i]["SUBJECT_NAME"] == ngx.null then
			record.stage_id 	= 0;
			record.subject_id 	= 0;
			record.subject_name = "--";
		else
			record.stage_id 	= res[i]["STAGE_ID"];
			record.subject_id 	= res[i]["SUBJECT_ID"];
			record.subject_name = res[i]["STAGE_NAME"] .. res[i]["SUBJECT_NAME"];
		end
		
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
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return resultJsonObj;
end

_CheckPerson.queryPersonByKeyAndOrg = queryPersonByKeyAndOrg;
---------------------------------------------------------------------------

--[[
	局部函数：获取该教师可以审核的单位
	作者：    申健 2015-03-09
	参数：    personId  		被设置的教师人员ID
	参数：    identityId  		被设置的教师的身份ID
	返回值：  boolean      		true是审核人员，false不是审核人员
]]
local function modifyCheckPerson(self, paramJson)
	
	local personId 		 = paramJson.person_id;
	local identityId 	 = paramJson.identity_id;
	local unitId 		 = paramJson.unit_id;
	local stageId 		 = paramJson.stage_id;
	local stageName 	 = paramJson.stage_name;
	local subjectId 	 = paramJson.subject_id;
	local subjectName 	 = paramJson.subject_name;
	local allowCheck 	 = paramJson.allow_check;
	local allowAddPerson = paramJson.allow_add_person;
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db  = DBUtil: getDb();
	
	local sqlTab = {};
	
	-- 删除用户与科目的关联关系
	local sql = "DELETE FROM T_BASE_CHECK_PERSON_SUBJECT WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " AND SUBJECT_ID=" .. subjectId .. ";";
	table.insert(sqlTab, sql);
	
	-- 更新用户表的 ALLOW_ADD_PERSON 和 ALLOW_CHECK 权限字段
	sql = "UPDATE T_BASE_CHECK_PERSON SET ALLOW_ADD_PERSON=" .. allowAddPerson .. ", ALLOW_CHECK=" .. allowCheck .. " WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
	table.insert(sqlTab, sql);
	
	-- 重新插入审核人员与科目的关联关系
	sql = "INSERT INTO T_BASE_CHECK_PERSON_SUBJECT(UNIT_ID, PERSON_ID, IDENTITY_ID, STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME) VALUES  (".. unitId .. "," .. personId .. "," .. identityId .. "," .. stageId .. ",'" .. stageName .. "'," .. subjectId .. ",'" .. subjectName .. "');";
	table.insert(sqlTab, sql);
	
	local result = DBUtil:batchExecuteSqlInTx(sqlTab, 50);
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return result;
	
end

---------------------------------------------------------------------------
--[[
	局部函数：访问其它请求，并将返回的值组装成table对象
	参数：url 	 		 接口地址
	参数：paramStr 	     参数字符串
	参数：methodType	 请求方式：GET 或 POST
]]
local function _getResponseJson(url, paramStr, methodType)
	local response;
	if methodType == "GET" then
	
		response = ngx.location.capture(url .. "?" .. paramStr, {
			method = ngx.HTTP_GET
		});
		
	elseif methodType == "POST" then
	
		response = ngx.location.capture(url, {
			method = ngx.HTTP_POST,
			body = paramStr
		});
	end
	
	if response.status == 200 then
		local cjson = require "cjson";
		local responseJson = cjson.decode(response.body);
		ngx.log(ngx.ERR, "===> 调用接口的返回值 ===> " , response.body);
		return responseJson;
	else
		return { success=true, info="访问请求失败！"};
	end
end 

---------------------------------------------------------------------------

--[[
	局部函数：维护审核人员
	作者：    申健 2015-03-17
	参数：    personId  		被设置的教师人员ID
	参数：    identityId  		被设置的教师的身份ID
	返回值：  boolean      		true是审核人员，false不是审核人员
]]
local function setCheckPerson(self, unitId, paramJson)
	
	local personId 		 = paramJson.person_id;
	local identityId 	 = paramJson.identity_id;
	local personName	 = paramJson.person_name;
	local allowCheck 	 = paramJson.allow_check;
	local allowAddPerson = paramJson.allow_add_person;
	local subjectList	 = paramJson.subject_List;
	
	local DBUtil = require "multi_check.model.DBUtil";
	local db  = DBUtil: getDb();
	
	local sqlTab = {};
	local sql    = "";
	
	-- 判断用户是否存在
	local isPersonExist = isCheckPersonExist(self, unitId, personId, identityId, 0);
	
	if isPersonExist then
		-- 删除用户与科目的关联关系
		sql = "DELETE FROM T_BASE_CHECK_PERSON_SUBJECT WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
		table.insert(sqlTab, sql);
		
		sql = "UPDATE T_BASE_CHECK_PERSON SET ALLOW_ADD_PERSON=" .. allowAddPerson .. ", ALLOW_CHECK=" .. allowCheck .. " WHERE UNIT_ID=" .. unitId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. ";";
		table.insert(sqlTab, sql);
	else
		-- 获取调用此请求的方式GET/POST
		local request_method = ngx.var.request_method;
		-- 要访问的接口url
		local url 	   = "/dsideal_yy/management/person/getOrgInfoByPerson";
		-- 调用接口所传递的参数
		local paramStr = "person_id=".. personId .. "&identity_id=" .. identityId .. "&type=0";
		
		local responseJson 	= _getResponseJson(url, paramStr, request_method);
		local provinceName 	= responseJson.province_name;
		local cityName 		= responseJson.city_name;
		local districtName 	= responseJson.district_name;
		local schoolName 	= responseJson.school_name;
		local orgName   	= responseJson.org_name;
		
		-- 根据单位ID获取单位类型
		local unitType = self: getUnitType(unitId);
		local unitName = "";
		if unitType == 1 then
			unitName = provinceName;
		elseif unitType == 2 then
			unitName = cityName;
		elseif unitType == 3 then
			unitName = districtName;
		elseif unitType == 4 then 
			unitName = schoolName;
		end
		
		sql = "INSERT INTO T_BASE_CHECK_PERSON (UNIT_ID, PERSON_ID, IDENTITY_ID, PERSON_NAME, UNIT_NAME, B_USE, SET_TIME, PROVINCE_NAME, CITY_NAME, DISTRICT_NAME, SCHOOL_NAME, ORG_NAME, ALLOW_CHECK, ALLOW_ADD_PERSON ) VALUES (".. unitId .. "," .. personId .. "," .. identityId .. ",'" .. personName .. "','" .. unitName .. "', 1, NOW(), '" .. provinceName .. "', '" .. cityName .. "', '" .. districtName .. "', '" .. schoolName .. "','" .. orgName .. "'," .. allowCheck .. "," .. allowAddPerson .. ");";
		
		table.insert(sqlTab, sql);
	end
		
	-- 循环前台发送过来的学科数组，获取学科信息
	for index=1, #subjectList do
		
		local subjectObj 	= subjectList[index];
		local stageId 		= subjectObj.stage_id;
		local stageName 	= subjectObj.stage_name;
		local subjectId 	= subjectObj.subject_id;
		local subjectName 	= subjectObj.subject_name;
		
		-- 重新插入审核人员与科目的关联关系
		sql = "INSERT INTO T_BASE_CHECK_PERSON_SUBJECT(UNIT_ID, PERSON_ID, IDENTITY_ID, STAGE_ID, STAGE_NAME, SUBJECT_ID, SUBJECT_NAME) VALUES (".. unitId .. "," .. personId .. "," .. identityId .. "," .. stageId .. ",'" .. stageName .. "'," .. subjectId .. ",'" .. subjectName .. "');";
		table.insert(sqlTab, sql);
		
	end

	local result = DBUtil:batchExecuteSqlInTx(sqlTab, 50);
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return result;
	
end
_CheckPerson.setCheckPerson = setCheckPerson;

---------------------------------------------------------------------------



return _CheckPerson;