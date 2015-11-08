--[[
	申健	2015-04-22
	描述：机构（省、市、区、校、部门、班级）信息基础接口
]]
local _OrgService = {};

---------------------------------------------------------------------------
--[[
	局部函数： 异步获取机构树的接口
	参数：	 orgId	 	机构ID
	参数：	 orgType	机构类型：1省，2市，3区，4校，5分校，6部门，7班级
	参数：	 nextFlag	是否获取下级单位：0获取当前， 1获取下级
	返回：	 存储单个省信息的Table对象
]]
local function getAsyncOrgTree(self, orgId, orgType, nextFlag)

	local DBUtil   = require "common.DBUtil";
	local orgTable = {};
	if orgType == 0 then -- 0 获取所有省
		local provinceModel   = require "base.org.model.Province";
		if nextFlag == 0 then 
			local provinceRecord = provinceModel: getById(orgId);
			local orgRecord  = {};
			orgRecord["id"]       = provinceRecord["ID"];
			orgRecord["name"]     = provinceRecord["PROVINCENAME"];
			orgRecord["org_type"] = provinceRecord["ORGA_TYPE"];
			orgRecord["pId"]      = provinceRecord["PID"];
			table.insert(orgTable, orgRecord);
		else
			local provinceResults = provinceModel: getAllProvince(orgId);
			for index = 1, #provinceResults do
				local provinceRecord = provinceResults[index];
				local orgRecord  = {};
				orgRecord["id"]       = provinceRecord["ID"];
				orgRecord["name"]     = provinceRecord["PROVINCENAME"];
				orgRecord["org_type"] = provinceRecord["ORGA_TYPE"];
				orgRecord["pId"]      = provinceRecord["PID"];
				table.insert(orgTable, orgRecord);
			end
		end
		
	elseif orgType == 1 then -- 获取指定省下的所有市
		
		if nextFlag == 0 then 
			local provinceModel   = require "base.org.model.Province";
			local provinceRecord  = provinceModel: getById(orgId);
			local orgRecord  = {};
			orgRecord["id"]       = provinceRecord["ID"];
			orgRecord["name"]     = provinceRecord["PROVINCENAME"];
			orgRecord["org_type"] = provinceRecord["ORGA_TYPE"];
			orgRecord["pId"]      = provinceRecord["PID"];
			table.insert(orgTable, orgRecord);
		else
			local cityModel   = require "base.org.model.City";
			local cityResults = cityModel: getByProvinceId(orgId);
			for index = 1, #cityResults do
				local cityRecord = cityResults[index];
				local orgRecord  = {};
				orgRecord["id"]       = cityRecord["ID"];
				orgRecord["name"]     = cityRecord["CITYNAME"];
				orgRecord["org_type"] = cityRecord["ORGA_TYPE"];
				orgRecord["pId"]      = cityRecord["PID"];
				table.insert(orgTable, orgRecord);
			end
		end
	elseif orgType == 2 then -- 获取指定市下的所有区
		if nextFlag == 0 then 
			local cityModel   = require "base.org.model.City";
			local cityRecord  = cityModel: getById(orgId);
			local orgRecord  = {};
			orgRecord["id"]       = cityRecord["ID"];
			orgRecord["name"]     = cityRecord["CITYNAME"];
			orgRecord["org_type"] = cityRecord["ORGA_TYPE"];
			orgRecord["pId"]      = cityRecord["PID"];
			table.insert(orgTable, orgRecord);
		else
			local districtModel   = require "base.org.model.District";
			local districtResults = districtModel: getByCityId(orgId);
			for index = 1, #districtResults do
				local districtRecord = districtResults[index];
				local orgRecord  = {};
				orgRecord["id"]       = districtRecord["ID"];
				orgRecord["name"]     = districtRecord["DISTRICTNAME"];
				orgRecord["org_type"] = districtRecord["ORGA_TYPE"];
				orgRecord["pId"]      = districtRecord["PID"];
				table.insert(orgTable, orgRecord);
			end
		end
    elseif orgType == 3 then -- 获取指定区下的所有学校
		
		if nextFlag == 0 then 
			local districtModel   = require "base.org.model.District";
			local districtRecord = districtModel: getById(orgId);
			local orgRecord  = {};
			orgRecord["id"]       = districtRecord["ID"];
			orgRecord["name"]     = districtRecord["DISTRICTNAME"];
			orgRecord["org_type"] = districtRecord["ORGA_TYPE"];
			orgRecord["pId"]      = districtRecord["PID"];
			table.insert(orgTable, orgRecord);
		else
			local schoolModel   = require "base.org.model.School";
			local schoolResults = schoolModel: getByDistrictNoPage(orgId);
			for index = 1, #schoolResults do
				local schoolRecord = schoolResults[index];
				local orgRecord    = {};
				orgRecord["id"]          = schoolRecord["ORG_ID"];
				orgRecord["name"]        = schoolRecord["ORG_NAME"];
				orgRecord["org_type"]    = schoolRecord["ORGA_TYPE"];
				orgRecord["pId"]         = schoolRecord["PID"];
				orgRecord["province_id"] = schoolRecord["PROVINCE_ID"];
				orgRecord["city_id"]     = schoolRecord["CITY_ID"];
				orgRecord["district_id"] = schoolRecord["DISTRICT_ID"];
				table.insert(orgTable, orgRecord);
			end
		end
	elseif orgType == 4 then -- 获取指定学校的班级
		if nextFlag == 0 then 
			local schoolModel   = require "base.org.model.School";
			local schoolRecord = schoolModel: getById(orgId);
			local orgRecord    = {};
			orgRecord["id"]       = schoolRecord["ORG_ID"];
			orgRecord["name"]     = schoolRecord["ORG_NAME"];
			orgRecord["org_type"] = schoolRecord["ORGA_TYPE"];
			orgRecord["pId"]      = schoolRecord["DISTRICT_ID"];
			table.insert(orgTable, orgRecord);
		else
			local classModel   = require "base.org.model.Class";
			local classResults = classModel: getBySchoolNoPage(orgId);
			for index = 1, #classResults do
				local classRecord = classResults[index];
				local orgRecord    = {};
				orgRecord["id"]          = classRecord["CLASS_ID"];
				orgRecord["name"]        = classRecord["CLASS_NAME"];
				orgRecord["org_type"]    = classRecord["ORGA_TYPE"];
				orgRecord["pId"]         = classRecord["BUREAU_ID"];
				orgRecord["province_id"] = classRecord["PROVINCE_ID"];
				orgRecord["city_id"]     = classRecord["CITY_ID"];
				orgRecord["district_id"] = classRecord["DISTRICT_ID"];
				table.insert(orgTable, orgRecord);
			end
		end
	end
	return orgTable;
end

_OrgService.getAsyncOrgTree = getAsyncOrgTree;

---------------------------------------------------------------------------
--[[
	局部函数： 异步获取机构树的接口
	参数：	 orgId	 	机构ID
	参数：	 orgType	机构类型：1省，2市，3区，4校，5分校，6部门，7班级
	返回：	 存储单个省信息的Table对象
]]
local function querySchoolByOrgWithPage(self, paramTable)
	local schoolModel   = require "base.org.model.School";
	local schoolResults = schoolModel: queryByOrgWithPage(paramTable);

	return schoolResults;

end

---------------------------------------------------------------------------
--[[
	局部函数： 异步获取机构树的接口
	参数：	 orgId	 	机构ID
	参数：	 orgType	机构类型：1省，2市，3区，4校，5分校，6部门，7班级
	返回：	 存储单个省信息的Table对象
]]
local function getSchoolByIds(self, schoolIds)
	local schoolModel   = require "base.org.model.School";
	local schoolResults = schoolModel: getBySchoolIds(schoolIds);

	return schoolResults;
end

_OrgService.getBySchoolIds = getBySchoolIds;
---------------------------------------------------------------------------

return _OrgService;