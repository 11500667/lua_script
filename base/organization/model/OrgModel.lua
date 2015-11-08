--[[

	组织相关接口 by huyue 2015-08-25
]]
--[[
    描述：根据组织ID获取一层子节点
]]

local _OrgModel = {};
local function getChildrenOrgs(self,orgId,orgType)
	local resultTable = {};
	local DBUtil = require "common.DBUtil";
	local query_condition = "WHERE  B_GROUP = 0"
	if orgId == nil or orgId =="" then 
	else
		query_condition = query_condition.." AND PARENT_ID = "..orgId;
	end
	if orgType == nil or orgType =="" then 
	else
		query_condition = query_condition.." AND ORG_TYPE in ( "..orgType..")";
	end
	local query_sql="SELECT T1.ORG_ID,T1.ORG_NAME,T1.JP,T2.TYPE_NAME,T1.ADDRESS,T1.CREATE_TIME,T1.AREA_ID,T1.ORG_TYPE FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID "..query_condition;
	ngx.log(ngx.ERR,"查询子组织SQL："..query_sql);
	local res=DBUtil: querySingleSql(query_sql);
	if not res or not res[1] then 
		return result;
	end
	for i=1,#res do
		local org_res = {}
		org_res["ORG_ID"] = res[i]["ORG_ID"]
		org_res["ORG_NAME"] = res[i]["ORG_NAME"]
		org_res["TYPE_NAME"] = res[i]["TYPE_NAME"]
		org_res["ADDRESS"] = res[i]["ADDRESS"]
		org_res["CREATE_TIME"] = res[i]["CREATE_TIME"]
		org_res["AREA_ID"] = res[i]["AREA_ID"]
		org_res["ORG_TYPE"] = res[i]["ORG_TYPE"]
		org_res["JP"] = res[i]["JP"]
		table.insert(resultTable, org_res);
	end
	return resultTable;
end

_OrgModel.getChildrenOrgs = getChildrenOrgs;
---------------------------------------------------------------------------
local function getHierarchyChildrenOrgs(self,orgId,orgType)
	local resultTable = {};
	local DBUtil = require "common.DBUtil";
	local query_condition = "WHERE  B_GROUP = 0"
	if orgId == nil or orgId =="" then 
	else
		query_condition = query_condition.." AND ORG_CODE like'%/_"..orgId.."/_%'  escape '/'"
	end
	if orgType == nil or orgType =="" then 
	else
		query_condition = query_condition.." AND ORG_TYPE in ( "..orgType..")";
	end
	local query_sql="SELECT T1.ORG_ID,T1.ORG_NAME,T1.JP,T2.TYPE_NAME,T1.ADDRESS,T1.CREATE_TIME,T1.AREA_ID,T1.ORG_TYPE FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID "..query_condition;
	ngx.log(ngx.ERR,"查询子组织SQL："..query_sql);
	local res=DBUtil: querySingleSql(query_sql);
	if not res or not res[1] then 
		return result;
	end
	for i=1,#res do
		local org_res = {}
		org_res["ORG_ID"] = res[i]["ORG_ID"]
		org_res["ORG_NAME"] = res[i]["ORG_NAME"]
		org_res["TYPE_NAME"] = res[i]["TYPE_NAME"]
		org_res["ADDRESS"] = res[i]["ADDRESS"]
		org_res["CREATE_TIME"] = res[i]["CREATE_TIME"]
		org_res["AREA_ID"] = res[i]["AREA_ID"]
		org_res["ORG_TYPE"] = res[i]["ORG_TYPE"]
		org_res["JP"] = res[i]["JP"]
		table.insert(resultTable, org_res);
	end
	return resultTable;
end

_OrgModel.getHierarchyChildrenOrgs = getHierarchyChildrenOrgs;
---------------------------------------------------------------------------
--[[
    描述：根据组织ID获取组织详情
]]
local function getOrgByOrgId(self,orgId)
	local DBUtil = require "common.DBUtil";
	ngx.log(ngx.ERR, "**********根据组织ID获取教育单位开始**********"); 
	local querysql = "SELECT T1.ORG_ID,T1.JP,T1.ORG_NAME,T2.TYPE_NAME,T1.DESCRIPTION,T1.EDU_TYPE,T1.SCHOOL_TYPE,T1.ADDRESS,T1.CREATE_TIME,T1.BUSINESS_SYSTEM_SOURCE,T1.AREA_ID,T1.ORG_TYPE,T1.MAIN_SCHOOL_ID,T1.PARENT_ID,T1.SORT_ID,T1.DISTRICT_ID,T1.CITY_ID,T1.PROVINCE_ID FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE 1=1 and ORG_ID="..orgId;
	local querysql_res = DBUtil: querySingleSql(querysql)

	if querysql_res[1] == nil then
	  return;
	end

	local ORG_ID = querysql_res[1]["ORG_ID"]
	local ORG_NAME = querysql_res[1]["ORG_NAME"]
	local TYPE_NAME = querysql_res[1]["TYPE_NAME"]
	local ADDRESS = querysql_res[1]["ADDRESS"]
	local CREATE_TIME = querysql_res[1]["CREATE_TIME"]
	local AREA_ID = querysql_res[1]["AREA_ID"]
	local ORG_TYPE = querysql_res[1]["ORG_TYPE"]
	local MAIN_SCHOOL_ID = querysql_res[1]["MAIN_SCHOOL_ID"]
	local PARENT_ID = querysql_res[1]["PARENT_ID"]
	local SORT_ID = querysql_res[1]["SORT_ID"]
	local EDU_TYPE=querysql_res[1]["EDU_TYPE"]
	local SCHOOL_TYPE = querysql_res[1]["SCHOOL_TYPE"]
	local DISTRICT_ID = querysql_res[1]["DISTRICT_ID"]
	local CITY_ID = querysql_res[1]["CITY_ID"]
	local PROVINCE_ID = querysql_res[1]["PROVINCE_ID"]
	local JP = querysql_res[1]["JP"]
	local DESCRIPTION = querysql_res[1]["DESCRIPTION"]
	local BUSINESS_SYSTEM_SOURCE=querysql_res[1]["BUSINESS_SYSTEM_SOURCE"]
	local MAIN_SCHOOL_NAME;
	local returnjson = {}
	if MAIN_SCHOOL_ID == ngx.null or tonumber(MAIN_SCHOOL_ID) == tonumber(orgId) then

	else
	  local school_id_str = " and ORG_ID="..MAIN_SCHOOL_ID
	  local quertsql_1 = "select ORG_NAME FROM T_BASE_ORGANIZATION  WHERE 1=1 "..school_id_str
	  local querysql_res1 = DBUtil: querySingleSql(quertsql_1)
	  if querysql_res1[1] == nil then
		return false;
	  else
		if querysql_res1[1]["ORG_NAME"] ~= ngx.null then
		MAIN_SCHOOL_NAME = querysql_res1[1]["ORG_NAME"];
		returnjson["MAIN_SCHOOL_NAME"] = MAIN_SCHOOL_NAME;
		end
	  end
	end
	returnjson["ORG_ID"] = ORG_ID
	returnjson["ORG_NAME"] = ORG_NAME
	returnjson["TYPE_NAME"] = TYPE_NAME
	returnjson["ADDRESS"] = ADDRESS
	returnjson["CREATE_TIME"] = CREATE_TIME
	returnjson["AREA_ID"] = AREA_ID
	returnjson["ORG_TYPE"] = ORG_TYPE
	returnjson["MAIN_SCHOOL_ID"] = MAIN_SCHOOL_ID
	returnjson["PARENT_ID"] = PARENT_ID
	returnjson["SORT_ID"] = SORT_ID
	returnjson["EDU_TYPE"] = EDU_TYPE
	returnjson["SCHOOL_TYPE"] = SCHOOL_TYPE
	returnjson["DISTRICT_ID"] = DISTRICT_ID
	returnjson["CITY_ID"] = CITY_ID
	returnjson["PROVINCE_ID"] = PROVINCE_ID
	returnjson["JP"] = JP
	returnjson["BUSINESS_SYSTEM_SOURCE"] = BUSINESS_SYSTEM_SOURCE
	returnjson["DESCRIPTION"] = DESCRIPTION

	return returnjson;

end

_OrgModel.getOrgByOrgId = getOrgByOrgId;
---------------------------------------------------------------------------
--[[
    描述：根据组织ID获取上级单位
]]
local function getSupOrgByOrgId(self,org_id)
	local query_org_code_sql="select org_code from t_base_organization where org_id="..org_id;
	local result={};
	local DBUtil = require "common.DBUtil";
	local query_org_code_res= DBUtil: querySingleSql(query_org_code_sql);
	if query_org_code_res==nil or query_org_code_res[1]==nil then 
	
		return result;
	end
	local org_code=query_org_code_res[1]["org_code"];
	local m=1;
	local org_code_arr=Split(org_code,"_");
	for index=1,#org_code_arr do 
		local parent_id = org_code_arr[index];
		if parent_id~=nil and parent_id ~= "" and tonumber(parent_id)~= tonumber(org_id) then 
			local org_res = self:getOrgByOrgId(parent_id);
			if org_res then
				local org_table={};
				org_table["ORG_ID"]=org_res["ORG_ID"];
				org_table["ORG_NAME"]=org_res["ORG_NAME"];
				org_table["ORG_TYPE"]=org_res["ORG_TYPE"];
				table.insert(result, org_table);
			end
		
		end
		
	end
	
	return result;
end

_OrgModel.getSupOrgByOrgId = getSupOrgByOrgId;
---------------------------------------------------------------------------

--[[
	获取组织树
]]
local function getOrgTree(self,org_id,org_type) 
	local DBUtil = require "common.DBUtil";
	
	local query_sql = "SELECT ORG_ID,ORG_NAME,PARENT_ID ,ORG_CODE,SORT_ID FROM T_BASE_ORGANIZATION WHERE ORG_CODE like'%/_"..org_id.."/_%'  escape '/' ";
	if org_type==nil or org_type=="" then 
	else
		query_sql=query_sql.." and org_type in("..org_type..") ";
	end
	query_sql=query_sql.." order by sort_id"
	ngx.log(ngx.ERR,"org_log----------->"..query_sql);

	local query_res = DBUtil: querySingleSql(query_sql)
	local org_tab = {}
	for i=1,#query_res do
		local org_res = {}
		org_res["id"] = query_res[i]["ORG_ID"]
		org_res["name"] = query_res[i]["ORG_NAME"]
		org_res["pId"] = query_res[i]["PARENT_ID"]
		org_res["open"] = false;
		org_res["org_code"] = query_res[i]["ORG_CODE"]
		org_res["sort_id"] = query_res[i]["SORT_ID"]
		org_tab[i] = org_res
end

	return org_tab;
end
_OrgModel.getOrgTree = getOrgTree;
--[[

--根据组织ID检查是否是否有分校
]]
local function checkHaveBranchSchool(self,org_id)
	local DBUtil = require "common.DBUtil";
	local query_sql = "SELECT count(1) as count FROM T_BASE_ORGANIZATION WHERE MAIN_SCHOOL_ID ="..org_id;
	ngx.log(ngx.ERR,"org_log----------->"..query_sql);
	local query_res = DBUtil: querySingleSql(query_sql);
	local count = tonumber(query_res[1]["count"])
	if count > 0 then
	   return true;
	else
		return false;
	end

end
_OrgModel.checkHaveBranchSchool= checkHaveBranchSchool;
---------------------------------------------------------------------------
--[[
获取分校及其组织信息
]]
local function getBranchSchoolAndOrg(self,org_id) 
	local DBUtil = require "common.DBUtil";
	local query_branch_school_sql = "SELECT ORG_ID ,ORG_NAME,ORG_CODE FROM T_BASE_ORGANIZATION WHERE MAIN_SCHOOL_ID ="..org_id;

	ngx.log(ngx.ERR,"org_log----------->"..query_branch_school_sql);
	local query_res = DBUtil: querySingleSql(query_branch_school_sql);
	local org_tab = {}
	local m=1;
	local query_current_school_sql="SELECT ORG_ID ,ORG_NAME,ORG_CODE FROM T_BASE_ORGANIZATION WHERE ORG_ID ="..org_id;
	local query_current_school_res = DBUtil: querySingleSql(query_current_school_sql);
	local current_school_res={};
	current_school_res["id"] = org_id;
	current_school_res["name"] = query_current_school_res[1]["ORG_NAME"];
	current_school_res["pId"] = 1
	current_school_res["open"] = true;
	org_tab[m] = current_school_res;
	m=m+1;
	for i=1,#query_res do
		local branch_school_id = query_res[i]["ORG_ID"];
		local query_branch_org_sql = "SELECT ORG_ID ,ORG_NAME,PARENT_ID ,ORG_CODE FROM T_BASE_ORGANIZATION WHERE ORG_CODE  like'%/_"..branch_school_id.."/_%'  escape '/'";
		ngx.log(ngx.ERR,"查询分校组织的SQL："..query_branch_org_sql);
		local query_org_res = DBUtil: querySingleSql(query_branch_org_sql);
		for j=1,#query_org_res do
			local org_res = {}
			org_res["id"] = query_org_res[j]["ORG_ID"]
			org_res["name"] = query_org_res[j]["ORG_NAME"]
			org_res["pId"] = query_org_res[j]["PARENT_ID"]
			org_res["open"] = true;
			org_res["org_code"] = query_org_res[j]["ORG_CODE"]
			org_tab[m] = org_res;
			m=m+1;
		end
		
	end
	return org_tab;
end
_OrgModel.getBranchSchoolAndOrg= getBranchSchoolAndOrg;
---------------------------------------------------------------------------
--[[

	根据行政区划Id获取默认教育局

]]

local function getDefaultEducationBureau(self,area_id) 
	local DBUtil = require "common.DBUtil";
	local query_sql="select org_id,org_name from t_base_organization where org_type=1 and area_id="..area_id;
	ngx.log(ngx.ERR,"查询默认上级单位的SQL："..query_sql);
	local result= DBUtil: querySingleSql(query_sql);
	return result;
end
_OrgModel.getDefaultEducationBureau = getDefaultEducationBureau;
---------------------------------------------------------------------------
return _OrgModel;