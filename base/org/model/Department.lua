--[[
	局部函数：部门信息基础接口
]]
local _DepartmentModel = {};

---------------------------------------------------------------------------
--[[
	局部函数：获取人员的详细信息（待完善），包括教师和学生
	参数：	personId 	 	人员ID
	参数：	identityId   	身份ID
]]
local function getPersonDetail(self, personId, identityId)
	
end

_DepartmentModel.getPersonDetail = getPersonDetail;

---------------------------------------------------------------------------
--[[
	局部函数：获取人员的姓名
	参数：	personId 	 	人员ID
	参数：	identityId   	身份ID
]]
local function getPersonName(self, personId, identityId)
	
end

_DepartmentModel.getPersonName = getPersonName;

---------------------------------------------------------------------------

return _DepartmentModel;