--[[
	申健	2015-04-23
	描述：   学校信息基础接口
]]
local _ClassService = {};


---------------------------------------------------------------------------
--[[
	局部函数： 根据条件获取指定机构及其子机构下的班级
	参数：	 paramTable	 	保存条件的table对象
	返回：	 存储查询结果的Table对象
]]
local function queryClassByOrgWithPage(self, paramTable)
	local classModel   = require "base.org.model.Class";
	local classResults = classModel: queryByOrgWithPage(paramTable);

	return classResults;

end

_ClassService.queryClassByOrgWithPage = queryClassByOrgWithPage;

---------------------------------------------------------------------------
--[[
	描述： 	根据多个ID获班级信息
	参数：	classIds	 	存储多个班级ID的table
	返回：	存储查询结果的Table对象
]]
local function getClassByIds(self, classIds)
	local cjson = require "cjson";
	ngx.log(ngx.ERR, "===> 根据多个ID查询学校的参数 ===> ", cjson.encode(classIds));
	local classModel   = require "base.org.model.Class";
	local classResults = classModel: getByClassIds(classIds);

	return classResults;
end

_ClassService.getClassByIds = getClassByIds;
---------------------------------------------------------------------------
--[[
	描述： 	根据多个ID获取班级信息
	参数：	classIds	 	存储多个学校ID的table
	返回：	存储查询结果的Table对象
]]
local function getClassByIds(self, classIds)
	local cjson = require "cjson";
	ngx.log(ngx.ERR, "===> 根据多个ID查询学校的参数 ===> ", cjson.encode(classIds));
	local classModel   = require "base.org.model.Class";
	local classResults = classModel: getByClassIds(classIds);

	return classResults;
end

_ClassService.getClassByIds = getClassByIds;
---------------------------------------------------------------------------

return _ClassService;