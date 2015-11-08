--[[
	申健	2015-04-23
	描述：   学校信息基础接口
]]
local _SchoolService = {};


---------------------------------------------------------------------------
--[[
	局部函数： 根据条件获取指定机构及其子机构下的学校
	参数：	 paramTable	 	保存条件的table对象
	返回：	 存储查询结果的Table对象
]]
local function querySchoolByOrgWithPage(self, paramTable)
	local schoolModel   = require "base.org.model.School";
	local schoolResults = schoolModel: queryByOrgWithPage(paramTable);

	return schoolResults;

end

_SchoolService.querySchoolByOrgWithPage = querySchoolByOrgWithPage;
---------------------------------------------------------------------------
--[[
	描述： 	根据多个ID获取学校信息
	参数：	schoolIds	 	存储多个学校ID的table
	返回：	存储查询结果的Table对象
]]
local function getSchoolByIds(self, schoolIds)
	local cjson = require "cjson";
	ngx.log(ngx.ERR, "===> 根据多个ID查询学校的参数 ===> ", cjson.encode(schoolIds));
	local schoolModel   = require "base.org.model.School";
	local schoolResults = schoolModel: getBySchoolIds(schoolIds);

	return schoolResults;
end

_SchoolService.getSchoolByIds = getSchoolByIds;
---------------------------------------------------------------------------

return _SchoolService;