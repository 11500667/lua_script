--[[
	胡悦
	行政区划信息基础接口
]]

local _AreaModel = {};

--[[
    描述：根据行政区划名称和行政区划类型查询行政区划
    作者： 胡悦 2015-08-19
    参数：    areaName,areaType
    返回值：存储结果的table
]]
local function getAreaList(self,areaName,areaType,parentId,pageNumber,pageSize)

	local DBUtil = require "common.DBUtil";
	local query_condition =" where 1=1 "
	if areaName == nil or areaName=="" then 
	
	else 
		query_condition=query_condition.." and t.area_name like '%"..areaName.."%'";
	end
	
	if areaType == nil or areaType=="" then 
	
	else
		query_condition=query_condition.." and t.area_type in ("..areaType..") "
	end
	
	if parentId == nil or parentId=="" then 
	
	else
		query_condition=query_condition.." and t.parent_id  = "..parentId;
	end
	
	local responseObj={}
	local sel_count= "select count(1) as COUNT from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t"..query_condition;
	
	local page_sql =""
	if pageSize==nil or pageSize == "" or pageNumber == nil or pageNumber =="" then

	else
		local offset = pageSize*pageNumber-pageSize
		local limit = pageSize

		page_sql = " LIMIT "..offset..","..limit..";"
		
		local res_count = DBUtil: querySingleSql(sel_count);
		local totalRow = res_count[1]["COUNT"]
		local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
		responseObj["totalRow"] = tonumber(totalRow)
		responseObj["totalPage"] = tonumber(totalPage)
		responseObj["pageNumber"] = tonumber(pageNumber)
		responseObj["pageSize"] = tonumber(pageSize)
	end
	
	
	local query_area_sql = "select ID AS AREA_ID,AREA_NAME,AREA_TYPE,PARENT_ID from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t"..query_condition..page_sql
	ngx.log(ngx.ERR,"hy_log-->查询行政区划SQL"..query_area_sql);
	local query_area_res=DBUtil: querySingleSql(query_area_sql);
	local resultTable = {};
	for i=1,#query_area_res do
		local area_res={};
		area_res["AREA_ID"]=query_area_res[i]["AREA_ID"];
		area_res["AREA_NAME"]=query_area_res[i]["AREA_NAME"];
		area_res["PARENT_ID"]=query_area_res[i]["PARENT_ID"];
		area_res["AREA_TYPE"]=query_area_res[i]["AREA_TYPE"];
		table.insert(resultTable, area_res);
	end
--	return { success=true, table_List=resultTable };
	responseObj["success"]=true;
	responseObj["table_List"]=resultTable;
	return responseObj;
end
_AreaModel.getAreaList = getAreaList;
---------------------------------------------------------------------------

--[[
	增加教育局
]]
local function addEducationBureau(self,area_id,area_name,area_type,parent_area_id)
	local result={};
	local DBUtil = require "common.DBUtil";
	local _SSDBUtil = require "common.SSDBUtil"
	local cjson = require "cjson"
	local org_id = _SSDBUtil: incr("t_base_group_new_pk");
	local bureau_name;
	if tonumber(area_type)==2 then
		bureau_name=area_name.."教育厅";
	else
		bureau_name=area_name.."教育局";
	end
	--1-直辖市;2-省;3-区;4-市;5-县
	
	local parent_id,org_code,level;
	ngx.log(ngx.ERR,area_type.."------------------------------");
	if tonumber(area_type) == 1 or tonumber(area_type)==2 then
		parent_id=0;
		org_code = "_"..org_id.."_";
		level=0;
	else
		local query_parent_sql = "select org_id,org_code,level from t_base_organization where org_type=1 and area_id = "..parent_area_id;	
		ngx.log(ngx.ERR,"查询父节点的SQL----->"..query_parent_sql);
		local query_parent_res= DBUtil: querySingleSql(query_parent_sql);
		if not query_parent_res or not query_parent_res[1] then
			result.success=false;
			return result;
		end
		parent_id = query_parent_res[1]["org_id"];
		org_code = tostring(query_parent_res[1]["org_code"])..org_id.."_";
		level = tonumber(query_parent_res[1]["level"])+1;
	
	end
	
	local insert_bureau_sql="insert into t_base_organization (ORG_ID, ORG_NAME, PARENT_ID,CREATE_TIME, BUREAU_ID, org_code, LEVEL,EDU_TYPE, AREA_ID, ORG_TYPE,B_USE, BUSINESS_SYSTEM_SOURCE) values ("..org_id..",'"..bureau_name.."',"..parent_id..",now(),"..org_id..",'"..org_code.."',"..level..",1,"..area_id..",1,1,'COMMON')";
	ngx.log(ngx.ERR,"hy_log-->插入教育局的SQL"..insert_bureau_sql);
	local insert_bureau_res=DBUtil: querySingleSql(insert_bureau_sql);
	
	--维护缓存开始
	local bureau_cache_sql="SELECT ORG_ID AS ID,ORG_NAME AS NAME,PARENT_ID AS PID FROM t_base_organization WHERE BUREAU_ID="..org_id.." ORDER BY SORT_ID DESC";
	ngx.log(ngx.ERR,"hy_log-->查询组织缓存的SQL"..bureau_cache_sql);
	local bureau_cache_res = DBUtil:querySingleSql(bureau_cache_sql);
	local bureau_cache_tab = {}
	for i=1,#bureau_cache_res do
	local bureau_table = {}
	bureau_table["id"] = bureau_cache_res[i]["ID"];
	bureau_table["pId"] = bureau_cache_res[i]["PID"];
	bureau_table["name"] = bureau_cache_res[i]["NAME"];
	bureau_cache_tab[i]=bureau_table;
	local _CacheUtil = require "common.CacheUtil";
	local cache = _CacheUtil.getRedisConn();
	cache:set("bureau_"..org_id,cjson.encode(bureau_cache_tab));
	cache:hmset("t_base_organization_"..org_id,"org_name",bureau_name,"bureau_id",org_id,"area_id",area_id);
	_CacheUtil:keepConnAlive(cache)
end
	result.success=true;
	result.org_id=org_id;
	return result;	
end
_AreaModel.addEducationBureau = addEducationBureau;
---------------------------------------------------------------------------

--[[
		生成登录名
]]	
local function  getLoginName(self,loginName) 
	ngx.log(ngx.ERR,loginName.."<><><><><><><><><><><><>");
	local DBUtil = require "common.DBUtil";
	local check_login_name_sql="select count(1) as count from t_sys_loginperson where login_name ='"..loginName.."'";
	local check_login_name_res=DBUtil:querySingleSql(check_login_name_sql);
	local count = check_login_name_res[1]["count"];
	local flag=false;
	if tonumber(count)>0 then
		flag=true;
	end
	if flag then
		loginName = loginName.."1";
		return self:getLoginName(loginName);
	else
		return loginName;
	end
end
_AreaModel.getLoginName = getLoginName;
---------------------------------------------------------------------------
--[[
	增加教育局管理员
]]
local function addEducationBureauAdmin(self,area_id,area_name,area_type,org_id,qp)
		local DBUtil = require "common.DBUtil";
		--8省管理员
		--9市管理员
		--10区县管理员
		--1-直辖市;2-省;3-区;4-市;5-县
		local org_name; 
		local identity_id=3
		local role_id;
		if tonumber(area_type)==2 then
			org_name = area_name.."教育厅管理员";
		
			role_id=61;
		elseif tonumber(area_type)==1 or tonumber(area_type)==4 then
		
			role_id=62;
			org_name = area_name.."教育局管理员";
		else
		
			role_id=63;
			org_name = area_name.."教育局管理员";
		end
	
		local query_area_res=self:getAreaInfoByAreaId(area_id);
	
		local province_id = query_area_res["province_id"];
		
		local city_id = query_area_res["city_id"];
		
		local district_id = query_area_res["district_id"];
		
		ngx.log(ngx.ERR,"province_id:"..province_id..",city_id:"..city_id..",district_id:"..district_id.."------------");
		
		local insert_person_sql="INSERT INTO T_BASE_PERSON( PERSON_NAME, ORG_ID, BUREAU_ID, PROVINCE_ID,CITY_ID,DISTRICT_ID,CREATE_TIME, B_USE, IDENTITY_ID )VALUES('"..org_name.."',"..org_id..","..org_id..","..province_id..","..city_id..","..district_id..",now(),1,"..identity_id..");";

		ngx.log(ngx.ERR,"hy_log插入行政区划管理员SQL->"..insert_person_sql);

		local insert_person_res=DBUtil:querySingleSql(insert_person_sql);

		local person_id = insert_person_res.insert_id;

		--增加登录账号

		local login_name;

		--根据身份获取登录名开头字符串
		local get_login_begin_sql = "SELECT LOGIN_BEGIN FROM T_SYS_IDENTITY WHERE IDENTITY_ID = "..identity_id;

		ngx.log(ngx.ERR,"org_log:get_login_begin_sql->"..get_login_begin_sql);

		local login_name_begin_res = DBUtil:querySingleSql(get_login_begin_sql);

		local login_name_begin="";
		if login_name_begin_res[1] == nil or login_name_begin_res[1]=="" then 

		else
			login_name_begin = login_name_begin_res[1]["LOGIN_BEGIN"];
		end

		ngx.log(ngx.ERR,"org_log:login_name_begin->"..login_name_begin);

		local login_name1 = login_name_begin..qp;
		--增加登录账号
		local login_name=self:getLoginName(login_name1);
		
		
		
		local login_password= ngx.md5(123456);
		local insert_loginperson_sql = "INSERT INTO T_SYS_LOGINPERSON(PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,PERSON_ID) VALUES('"..org_name.."','"..login_name.."','"..login_password.."',"..identity_id..",1,"..person_id..")";
		ngx.log(ngx.ERR,"org_log:insert_loginperson_sql->"..insert_loginperson_sql);

		local insert_loginperson_res = DBUtil:querySingleSql(insert_loginperson_sql);
		local role_id = "";
		--增加角色关系
		local insert_person_role_sql = "INSERT INTO T_SYS_PERSON_ROLE(PERSON_ID,ROLE_ID,IDENTITY_ID,ORG_ID) VALUES("..person_id..","..role_id..","..identity_id..","..org_id..")";
		ngx.log(ngx.ERR,"org_log:增加角色关系->"..login_name_begin);
		local insert_person_role_res = DBUtil:querySingleSql(insert_person_role_sql);
		--维护缓存开始
		local _CacheUtil = require "common.CacheUtil";
		local cache = _CacheUtil.getRedisConn();
		
		local token = ngx.md5(person_id.."_"..identity_id.."_dsideal4r5t6y7u");
		cache:hmset("login_"..login_name,"pwd",login_password,"person_id",person_id,"token",token,"identity_id",identity_id,"b_use",1,"person_name",unit_name);

		--角色缓存维护
		cache:rpush("role_"..person_id.."_"..identity_id,role_id);
		--人员地区缓存维护
		cache:hset("person_"..person_id.."_"..identity_id,"token",token);
		cache:hset("person_"..person_id.."_"..identity_id,"area_id",area_id);
		cache:hset("person_"..person_id.."_"..identity_id,"xiao",bureau_id);
		cache:hset("person_"..person_id.."_"..identity_id,"bm",org_id);
		_CacheUtil:keepConnAlive(cache)
end
_AreaModel.addEducationBureauAdmin = addEducationBureauAdmin;
---------------------------------------------------------------------------
--[[
	增加行政区划管理员
]]
local function addAreaAdmin(self,area_id,area_name,area_type,org_id,qp)
		local DBUtil = require "common.DBUtil";
		--8省管理员
		--9市管理员
		--10区县管理员
		--1-直辖市;2-省;3-市;4-区;5-县
		local org_name = area_name.."管理员";
		local identity_id;
		local role_code;
		if tonumber(area_type)==2 then
			identity_id=8;
			role_code="PROVINCE_ADMIN";
			
		elseif tonumber(area_type)==1 or tonumber(area_type)==3 then
			identity_id=9;
			role_code="CITY_ADMIN";
		else
			identity_id=10;
			role_code="DISTRICT_ADMIN";
		end
	
		local query_role_sql = "select role_id from t_sys_role where role_code = '"..role_code.."'";
		
		local query_role_res=DBUtil:querySingleSql(query_role_sql);
		
		local role_id = query_role_res[1]["role_id"];
		
		local query_area_res=self:getAreaInfoByAreaId(area_id);
	
		local province_id = query_area_res["province_id"];
		
		local city_id = query_area_res["city_id"];
		
		local district_id = query_area_res["district_id"];
		
		--ngx.log(ngx.ERR,"province_id:"..province_id..",city_id:"..city_id..",district_id:"..district_id.."------------");
		
		local insert_person_sql="INSERT INTO T_BASE_PERSON( PERSON_NAME, ORG_ID, BUREAU_ID, PROVINCE_ID,CITY_ID,DISTRICT_ID,CREATE_TIME, B_USE, IDENTITY_ID )VALUES('"..org_name.."',"..org_id..","..org_id..","..province_id..","..city_id..","..district_id..",now(),1,"..identity_id..");";

		ngx.log(ngx.ERR,"hy_log插入行政区划管理员SQL->"..insert_person_sql);

		local insert_person_res=DBUtil:querySingleSql(insert_person_sql);

		local person_id = insert_person_res.insert_id;
	
		--根据身份获取登录名开头字符串
		local get_login_begin_sql = "SELECT LOGIN_BEGIN FROM T_SYS_IDENTITY WHERE IDENTITY_ID = "..identity_id;

		ngx.log(ngx.ERR,"org_log:get_login_begin_sql->"..get_login_begin_sql);

		local login_name_begin_res = DBUtil:querySingleSql(get_login_begin_sql);

		local login_name_begin="";
		if login_name_begin_res[1] == nil or login_name_begin_res[1]=="" then 

		else
			login_name_begin = login_name_begin_res[1]["LOGIN_BEGIN"];
		end
		
		local login_name1 = login_name_begin..qp;
		ngx.log(ngx.ERR,"---------------"..login_name1);
		--增加登录账号
		local login_name=self:getLoginName(login_name1);
		
		local login_password= ngx.md5(123456);
		local insert_loginperson_sql = "INSERT INTO T_SYS_LOGINPERSON(PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,PERSON_ID) VALUES('"..org_name.."','"..login_name.."','"..login_password.."',"..identity_id..",1,"..person_id..")";
		ngx.log(ngx.ERR,"org_log:insert_loginperson_sql->"..insert_loginperson_sql);

		local insert_loginperson_res = DBUtil:querySingleSql(insert_loginperson_sql);
		local role_id = "";
		--增加角色关系
		local insert_person_role_sql = "INSERT INTO T_SYS_PERSON_ROLE(PERSON_ID,ROLE_ID,IDENTITY_ID,ORG_ID) VALUES("..person_id..","..role_id..","..identity_id..","..org_id..")";
		ngx.log(ngx.ERR,"org_log:增加角色关系->"..login_name_begin);
		local insert_person_role_res = DBUtil:querySingleSql(insert_person_role_sql);
		--维护缓存开始
		local _CacheUtil = require "common.CacheUtil";
		local cache = _CacheUtil.getRedisConn();
		
		local token = ngx.md5(person_id.."_"..identity_id.."_dsideal4r5t6y7u");
		cache:hmset("login_"..login_name,"pwd",login_password,"person_id",person_id,"token",token,"identity_id",identity_id,"b_use",1,"person_name",unit_name);

		--角色缓存维护
		cache:rpush("role_"..person_id.."_"..identity_id,role_id);
		--人员地区缓存维护
		cache:hset("person_"..person_id.."_"..identity_id,"token",token);
		cache:hset("person_"..person_id.."_"..identity_id,"area_id",area_id);
		cache:hset("person_"..person_id.."_"..identity_id,"xiao",bureau_id);
		cache:hset("person_"..person_id.."_"..identity_id,"bm",org_id);
		_CacheUtil:keepConnAlive(cache)
		
end
_AreaModel.addAreaAdmin = addAreaAdmin;
---------------------------------------------------------------------------

--[[
    描述：新增行政区划
    作者： 胡悦 2015-08-19
]]
local function addArea(self,area_name,parent_id,area_type,area_code,created_by)
	local result={}
	local DBUtil = require "common.DBUtil";
	--引用模块
	local cjson = require "cjson"
	--1 校验行政区划能否添加
	local check_code_sql="select count(1) as COUNT from (select id,provincename as area_name, -1 as parent_id,area_type,area_code from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type,area_code from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type,area_code from t_gov_district) t where t.area_code="..area_code;
	ngx.log(ngx.ERR,"hy_log-->验证行政区划国标码是否存在SQL："..check_code_sql);
	local check_code_res = DBUtil: querySingleSql(check_code_sql);
	if tonumber(check_code_res[1]["COUNT"]) >0 then  
		  result.success=false;
		  result.info=area_code.."已经存在不能重复添加";
		  return result;
	end
	local check_name_sql ="select count(1) as COUNT  from (select id,provincename as area_name, -1 as parent_id,area_type,area_code from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type,area_code from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type,area_code from t_gov_district) t where t.parent_id="..parent_id.." and area_name='"..area_name.."'";
	ngx.log(ngx.ERR,"hy_log-->验证行政区划名称是否存在SQL："..check_name_sql);
	local check_name_res = DBUtil: querySingleSql(check_name_sql);
	if tonumber(check_name_res[1]["COUNT"]) >0 then  
		  result.success=false;
		  result.info=area_name.."已经存在不能重复添加";
		  return result;
	end
	
	--2 插入行政区划
	local insert_area_sql;
	--2省  3市 4 区
	if tonumber(area_type)==2 then 
		local query_max_province_id = "select max(id) as id from t_gov_province";
		local query_max_province_id_res = DBUtil: querySingleSql(query_max_province_id);
		local province_id = tonumber(query_max_province_id_res[1]["id"])+1;
		insert_area_sql="insert into t_gov_province (ID,PROVINCENAME,area_code,area_type) values("..province_id..",'"..area_name.."',"..area_code..",2)";
	
	elseif tonumber(area_type)==3 then
		insert_area_sql="insert into t_gov_city(CITYNAME,PROVINCEID,AREA_CODE,AREA_TYPE) values('"..area_name.."',"..parent_id..","..area_code..",3)";
	elseif tonumber(area_type)==4 then
		insert_area_sql="insert into t_gov_district (DISTRICTNAME,CITYID,AREA_CODE,AREA_TYPE) values('"..area_name.."',"..parent_id..","..area_code..",4)";
	else
		  result.success=false;
		  result.info=area_type.."不合法！";
		  return result;
	
	end
	
	ngx.log(ngx.ERR,"hy_log-->插入行政区划的SQL"..insert_area_sql);
	local insert_area_res=DBUtil: querySingleSql(insert_area_sql);	
	
	local area_id = insert_area_res.insert_id;
	
	--3插入教育局

	local addEducationBureauResult = self:addEducationBureau(area_id,area_name,area_type,parent_id);
	local org_id;
	if addEducationBureauResult.success then 
		org_id = addEducationBureauResult.org_id;
		
	else 
		result=addEducationBureauResult;
		return result;
	
	end
	--获取行政区划的拼音
	local value = ngx.location.capture("/dsideal_yy/ypt/per/getQPByName?name="..area_name)
	local qp_result = cjson.decode(value.body);

	local qp=qp_result.qp;

	--4插入行政区划管理员
	local addAreaAdminResult = self:addAreaAdmin(area_id,area_name,area_type,org_id,qp);
	--5插入教育局管理员
	local addEducationBureauAdminResult= self:addEducationBureauAdmin(area_id,area_name,area_type,org_id,qp);
	result.success=true;
	result.info="新增行政区划成功!";
	return result;
end
_AreaModel.addArea = addArea;
---------------------------------------------------------------------------

--[[
	根据area_id 获取area信息
]]

local function getAreaInfoByAreaId(self,area_id)
	local result={};
	local DBUtil = require "common.DBUtil";
	local query_sql="select ID AS area_id,area_name,area_type,parent_id from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t where t.id="..area_id;
	ngx.log(ngx.ERR,"查询行政区划SQL："..query_sql);
	local query_res=DBUtil: querySingleSql(query_sql);
	if not query_res or not query_res[1] then 
		result.success="false";
		result.info="查不到行政区划";
		return result;
	end
	local area_id=query_res[1]["area_id"];
	local area_name = query_res[1]["area_name"];
	local area_type = query_res[1]["area_type"];
	local parent_id = query_res[1]["parent_id"];
	result.area_id = area_id;
	result.area_name = area_name;
	result.area_type=area_type;
	result.parent_id=parent_id;
	--1-直辖市;2-省;3-市;4-区;5-县
	if tonumber(area_type)== 1 then
		result.province_id = area_id;
		result.province_name = area_name;
		result.city_id = area_id;
		result.city_name = area_name;
		result.district_id = 0;
		result.district_name = "";
	elseif tonumber(area_type) == 2 then 
		result.province_id = area_id;
		result.province_name = area_name;
		result.city_id = 0;
		result.city_name = "";
		result.district_id = 0;
		result.district_name = "";
	
	elseif tonumber(area_type) == 3 then 
		local query_province_sql = "select ID AS area_id,area_name,area_type,parent_id  from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t where t.area_type=2 and t.id ="..parent_id;
		--"select area_id,area_name from t_base_area where area_type=2 and area_id ="..parent_id;
		ngx.log(ngx.ERR,"查询省的SQL："..query_province_sql);
		local query_province_res=DBUtil: querySingleSql(query_province_sql);
		if not query_province_res or not query_province_res[1] then 
			result.success="false";
			result.info="查不到省信息";
			return result;
		end
		result.province_id = query_province_res[1]["area_id"];
		result.province_name =query_province_res[1]["area_name"];
		result.city_id = area_id;
		result.city_name = area_name;
		result.district_id = 0;
		result.district_name = "";	
	elseif tonumber(area_type) == 4 or tonumber(area_type) == 5 then 
		local query_city_sql = "select ID AS area_id,area_name,area_type,parent_id  from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t where t.id ="..parent_id;
		ngx.log(ngx.ERR,"查询市的SQL--->"..query_city_sql);
		local query_city_res= DBUtil: querySingleSql(query_city_sql);
		if not query_city_res or not query_city_res[1] then 
			result.success="false";
			result.info="查不到市信息";
			return result;
		end
		local city_id = query_city_res[1]["area_id"];
		local city_name = query_city_res[1]["area_name"];
		local province_id = query_city_res[1]["parent_id"];
		local city_area_type=query_city_res[1]["area_type"];
		result.district_id = area_id;
		result.district_name = area_name;
		result.city_id = city_id;
		result.city_name = city_name;
		if tonumber(city_area_type) == 1 then 
			result.province_name = city_name;
			result.province_id = city_id;
			return result;
		end
		--查询省
		local query_province_sql ="select ID AS area_id,area_name,area_type,parent_id  from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t where t.area_type=2 and t.id ="..province_id;
		ngx.log(ngx.ERR,"查询省的SQL："..query_province_sql);
		local query_province_res=DBUtil: querySingleSql(query_province_sql);
		if not query_province_res or not query_province_res[1] then 
			result.success="false";
			result.info="查不到省信息";
			return result;
		end	
		result.province_name = query_province_res[1]["area_name"];	
		result.province_id = query_province_res[1]["area_id"];	
	end	
	ngx.log(ngx.ERR,"province_id:"..result.province_id..",city_id:"..result.city_id..",district_id:"..result.district_id.."------------");
	return result;
end

_AreaModel.getAreaInfoByAreaId = getAreaInfoByAreaId;
---------------------------------------------------------------------------
--[[
	根据area_id 获取行政区划树
]]
local function getAreaTree(self,area_id)
	local areaModel = require "base.area.model.AreaModel";
	local resultTable = {};
	--table.insert(resultTable, area_res);
	local DBUtil = require "common.DBUtil";
	if area_id == nil or area_id =="" then
		--String tree_data = "[{ \"id\":1, \"name\":\"中国行政区域\", \"isParent\":true}]";
		local result={};
		result.id = -1;
		result.name = "中国行政区域";
		result.isParent=true;
		table.insert(resultTable, result);
		return resultTable;
	else 
		local query_sql="select id AS area_id,area_name,area_type,parent_id from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t where t.parent_id="..area_id;
		ngx.log(ngx.ERR,"查询行政区划SQL："..query_sql);
		local query_res=DBUtil: querySingleSql(query_sql);
		if not query_res or not query_res[1] then 
			return result;
		end
		for index=1,#query_res do
			local result = {};
			result.id = query_res[index]["area_id"]
			result.name = query_res[index]["area_name"]
			
			local query_count_sql = "select count(1) AS COUNT from (select id,provincename as area_name, -1 as parent_id,area_type from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type from t_gov_district) t where t.parent_id ="..query_res[1]["area_id"];
			local query_count_res = DBUtil: querySingleSql(query_count_sql);
			if tonumber(query_count_res[1]["COUNT"]) >0 then  
			   result.isParent=true;
			else
				result.isParent=false;
			end
			table.insert(resultTable, result);
		end
		
	end
	return resultTable;

end
_AreaModel.getAreaTree = getAreaTree;

---------------------------------------------------------------------------
--[[
	修改行政区划  胡悦  2015-09-02
]]
local function  modifyArea(self,area_id,area_name,area_code)
	local  result={};
	--验证是否可以修改
	local DBUtil = require "common.DBUtil";
	--引用模块
	local cjson = require "cjson"
	--查询原来的值
	local area_original = self:getAreaInfoByAreaId(area_id);
	local parent_id = area_original["parent_id"];
	local area_name_original=area_original["area_name"];
	local area_type=area_original["area_type"];

	
	--1 校验行政区划能否添加
	local check_code_sql="select count(1) as COUNT from (select id,provincename as area_name, -1 as parent_id,area_type,area_code from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type,area_code from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type,area_code from t_gov_district) t where t.area_code="..area_code.." and t.id<>"..area_id;
	ngx.log(ngx.ERR,"hy_log-->验证行政区划国标码是否存在SQL："..check_code_sql);
	local check_code_res = DBUtil: querySingleSql(check_code_sql);
	if tonumber(check_code_res[1]["COUNT"]) >0 then  
		  result.success=false;
		  result.info=area_code.."已经存在不能重复添加";
		  return result;
	end
	local check_name_sql ="select count(1) as COUNT  from (select id,provincename as area_name, -1 as parent_id,area_type,area_code from t_gov_province union all select id,cityname as area_name,provinceid as parent_id,area_type,area_code from t_gov_city union all select id,districtname as area_name,cityid as parent_id,area_type,area_code from t_gov_district) t where t.parent_id="..parent_id.." and area_name='"..area_name.."' and t.id<>"..area_id;
	ngx.log(ngx.ERR,"hy_log-->验证行政区划名称是否存在SQL："..check_name_sql);
	local check_name_res = DBUtil: querySingleSql(check_name_sql);
	if tonumber(check_name_res[1]["COUNT"]) >0 then  
		  result.success=false;
		  result.info=area_name.."已经存在不能重复添加";
		  return result;
	end
	

	--1修改行政区划表
	local update_area_sql;
	--2省 3市 4区
	if tonumber(area_type)==2 then
		update_area_sql="update t_gov_province set PROVINCENAME='"..area_name.."',area_code="..area_code.." where id ="..area_id;
	elseif tonumber(area_type)==3 then 
		update_area_sql="update t_gov_city set CITYNAME='"..area_name.."',area_code="..area_code.." where id ="..area_id;
	elseif tonumber(area_type)== 4 then 
		update_area_sql="update t_gov_district set districtname='"..area_name.."',area_code="..area_code.." where id ="..area_id;
	end
	ngx.log(ngx.ERR,"hy_log------------>更新行政区划："..update_area_sql);
	local update_res=DBUtil: querySingleSql(update_area_sql);
	if tostring(original_area_name) ~= tostring(area_name) then 
		--修改教育局名称 
		local modifyEducationBureauResult = self:modifyEducationBureau(area_id,area_name,area_type,parent_id,area_name_original);
		--修改行政区划管理员和教育局管理员的名称
		--获取行政区划的拼音
		local value = ngx.location.capture("/dsideal_yy/ypt/per/getQPByName?name="..area_name)
		local qp_result = cjson.decode(value.body);
		local qp=qp_result.qp;
		
		--4修改行政区划管理员
		--(self,area_id,area_name,area_type,org_id,qp,area_name_original)
		local modifyAreaAdminResult = self:modifyAreaAdmin(area_id,area_name,area_type,parent_id,qp,area_name_original);
		--5修改教育局管理员
		local modifyEducationBureauAdminResult= self:modifyEducationBureauAdmin(area_id,area_name,area_type,qp,area_name_original);	
	end
	result.success=true;
	result.info="修改行政单位成功";
	return result;
end

_AreaModel.modifyArea = modifyArea;
---------------------------------------------------------------------------
--[[
	修改教育局名称
]]
local function modifyEducationBureau(self,area_id,area_name,area_type,parent_id,area_name_original)

	local result={};
	local DBUtil = require "common.DBUtil";
	local cjson = require "cjson"
	--查询原来的教育局
	local bureau_name;
	if tonumber(area_type)==2 then
		bureau_name=area_name.."教育厅";
		bureau_name_original= area_name_original.."教育厅";
	else
		bureau_name=area_name.."教育局";
		bureau_name_original= area_name_original.."教育局";
	end
	local query_original_org_sql="select org_id from t_base_organization where org_type=1 and area_id="..area_id.." and org_name='"..bureau_name_original.."'";
	
	ngx.log(ngx.ERR,"hy_log--------->查询原始组织的SQL："..query_original_org_sql);
	
	--查询原来的教育局
	
	local query_org_res=DBUtil: querySingleSql(query_original_org_sql);
	
	if query_org_res== nil or query_org_res[1]== nil then
		--如果没有则新增，有则修改
		result = self:addEducationBureau(area_id,area_name,area_type,parent_id);
		return result;
	end
	local original_org_id = query_org_res[1]["org_id"];
	
	--更新教育局名称
	local update_org_sql="update t_base_organization set org_name='"..bureau_name.."' where org_id="..original_org_id;
	
	ngx.log(ngx.ERR,"hy_log---------->更新教育局名称SQL："..update_org_sql);
	local update_org_res=DBUtil: querySingleSql(update_org_sql);

	--维护缓存开始
	local bureau_cache_sql="SELECT ORG_ID AS ID,ORG_NAME AS NAME,PARENT_ID AS PID FROM t_base_organization WHERE BUREAU_ID="..original_org_id.." ORDER BY SORT_ID DESC";
	ngx.log(ngx.ERR,"hy_log-->查询组织缓存的SQL"..bureau_cache_sql);
	local bureau_cache_res = DBUtil:querySingleSql(bureau_cache_sql);
	local bureau_cache_tab = {}
	for i=1,#bureau_cache_res do
		local bureau_table = {}
		bureau_table["id"] = bureau_cache_res[i]["ID"];
		bureau_table["pId"] = bureau_cache_res[i]["PID"];
		bureau_table["name"] = bureau_cache_res[i]["NAME"];
		bureau_cache_tab[i]=bureau_table;
		local _CacheUtil = require "common.CacheUtil";
		local cache = _CacheUtil.getRedisConn();
		cache:set("bureau_"..original_org_id,cjson.encode(bureau_cache_tab));
		cache:hmset("t_base_organization_"..original_org_id,"org_name",bureau_name,"bureau_id",original_org_id,"area_id",area_id);
		_CacheUtil:keepConnAlive(cache)

	end
end
_AreaModel.modifyEducationBureau = modifyEducationBureau;
---------------------------------------------------------------------------
--[[
	修改行政区划管理员
]]
local function modifyAreaAdmin(self,area_id,area_name,area_type,org_id,qp,area_name_original)
		local DBUtil = require "common.DBUtil";
		--查询原始的person 
		--8省管理员
		--9市管理员
		--10区县管理员
		--1-直辖市;2-省;3-市;4-区;5-县
		local org_name = area_name.."管理员";
		local org_name_original= area_name_original.."管理员";
		local identity_id;
		if tonumber(area_type)==2 then
			identity_id=8;
		elseif tonumber(area_type)==1 or tonumber(area_type)==3 then
			identity_id=9;
		else
			identity_id=10;
		end
		
		local query_original_person="select person_id from t_base_person where person_name='"..org_name_original.."' and identity_id="..identity_id;
		ngx.log(ngx.ERR,query_original_person);
		local query_person_res=DBUtil: querySingleSql(query_original_person);
		
		if query_person_res== nil or query_person_res[1]== nil then
			--如果没有则新增，有则修改
			result = self:addAreaAdmin(area_id,area_name,area_type,org_id,qp);
			return result;
		end
		local original_person_id = query_person_res[1]["person_id"];
		
		
		--更新人名
		local update_person_sql="update t_base_person set person_name='"..org_name.."' where person_id="..original_person_id;
		
		ngx.log(ngx.ERR,"hy_log---------->更新行政区划管理员的SQL："..update_person_sql);
		local update_person_res=DBUtil: querySingleSql(update_person_sql);
		
		local update_login_person_sql="update t_sys_loginperson set person_name='"..org_name.."' where person_id="..original_person_id.." and identity_id="..identity_id;
		
		ngx.log(ngx.ERR,"hy_log---------->更新行政区划管理员的SQL："..update_login_person_sql);
		local update_login_person_res=DBUtil: querySingleSql(update_login_person_sql);
		
		
		--维护缓存开始
		local _CacheUtil = require "common.CacheUtil";
		local cache = _CacheUtil.getRedisConn();
		
		
		local query_original_login_person="select login_name from t_sys_loginperson where person_id="..original_person_id.." and identity_id="..identity_id;
		
		ngx.log(ngx.ERR,"hy_log------------>查询登录名SQL："..query_original_login_person);
		
		local query_login_person_res=DBUtil: querySingleSql(query_original_login_person);
		
		local login_name = query_login_person_res[1]["login_name"];
		
		
		local token = ngx.md5(original_person_id.."_"..identity_id.."_dsideal4r5t6y7u");
		cache:hmset("login_"..login_name,"pwd",login_password,"person_id",original_person_id,"token",token,"identity_id",identity_id,"b_use",1,"person_name",unit_name);


		_CacheUtil:keepConnAlive(cache)
		
end
_AreaModel.modifyAreaAdmin = modifyAreaAdmin;
---------------------------------------------------------------------------

--[[
修改教育局管理员 

]]

local function modifyEducationBureauAdmin(self,area_id,area_name,area_type,qp,area_name_original)  

		local DBUtil = require "common.DBUtil";
		--8省管理员
		--9市管理员
		--10区县管理员
		--1-直辖市;2-省;3-区;4-市;5-县
		local org_name; 
		local org_name_original;
		local identity_id=3
		
		if tonumber(area_type)==2 then
			org_name = area_name.."教育厅管理员";
			org_name_original=area_name_original.."教育厅管理员";
		elseif tonumber(area_type)==1 or tonumber(area_type)==4 then
			org_name = area_name.."教育局管理员";
			org_name_original=area_name_original.."教育局管理员";
		else
			org_name = area_name.."教育局管理员";
			org_name_original=area_name_original.."教育局管理员";
		end
	
		local query_original_person="select person_id from t_base_person where person_name='"..org_name_original.."' and identity_id="..identity_id;
	
		local query_person_res=DBUtil: querySingleSql(query_original_person);
		
		if query_person_res== nil or query_person_res[1]== nil then
			--如果没有则新增，有则修改
			result = self:addEducationBureauAdmin(area_id,area_name,area_type,org_id,qp);
			return result;
		end
		local original_person_id = query_person_res[1]["person_id"];
		
		--更新人名
		local update_person_sql="update t_base_person set person_name='"..org_name.."' where person_id="..original_person_id;
		
		ngx.log(ngx.ERR,"hy_log---------->更新行政区划管理员的SQL："..update_person_sql);
		local update_person_res=DBUtil: querySingleSql(update_person_sql);
		
		local update_login_person_sql="update t_sys_loginperson set person_name='"..org_name.."' where person_id="..original_person_id.." and identity_id="..identity_id;
		
		ngx.log(ngx.ERR,"hy_log---------->更新行政区划管理员的SQL："..update_login_person_sql);
		local update_login_person_res=DBUtil: querySingleSql(update_login_person_sql);
	
	
		--维护缓存开始
		local _CacheUtil = require "common.CacheUtil";
		local cache = _CacheUtil.getRedisConn();
		local query_original_login_person="select login_name from t_sys_loginperson where person_id="..original_person_id.." and identity_id="..identity_id;
	
		local query_login_person_res=DBUtil: querySingleSql(query_original_login_person);
		
		local login_name = query_login_person_res[1]["login_name"];
		
		local token = ngx.md5(original_person_id.."_"..identity_id.."_dsideal4r5t6y7u");
		cache:hmset("login_"..login_name,"pwd",login_password,"person_id",original_person_id,"token",token,"identity_id",identity_id,"b_use",1,"person_name",unit_name);

		_CacheUtil:keepConnAlive(cache)

end
_AreaModel.modifyEducationBureauAdmin = modifyEducationBureauAdmin;
---------------------------------------------------------------------------
--[[
	修改行政区划  胡悦  2015-09-02
]]
local function  beforeDelArea(self,area_id)
	local result={}
	local current_area=self:getAreaInfoByAreaId(area_id);
	local current_area_code=current_area["area_code"];
	
	
	result.success=true;
	return result;
end

_AreaModel.beforeDelArea = beforeDelArea;
---------------------------------------------------------------------------
--[[

	级联查询行政区划 胡悦 2015-09-10
]]
local function getHierachyAreaByAreaId(self,area_id)


end
_AreaModel.getHierachyAreaByAreaId = getHierachyAreaByAreaId;
---------------------------------------------------------------------------
--[[
	修改行政区划  胡悦  2015-09-02
]]
local function  delArea(self,area_id)
	local result={}
	local areas={};
	
	--1 查询该行政区划的信息
	local current_area=self:getAreaInfoByAreaId(area_id);
	
	table.insert(areas, current_area);
	
	--2根据area_type 查询市 区的信息
	--local area_list
	
	
	--3组合这些area 查询组织
	
	
	--4根据组织查询班级
	
	--5根据班级删除学生
	
	--6根据行政区划删除 教师 和其他管理员
	
	--7删除登录账号
	
	--8删除组织
	
	--9删除行政区划
	
	--10删除行政区划
	
	
	--11维护 组织和人员的缓存
	
	result.success=true;
	result.info="删除行政区划成功！";
	return true;
end

_AreaModel.delArea = delArea;
---------------------------------------------------------------------------


return _AreaModel;
