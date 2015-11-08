
--[[
	胡悦 	2015-07-11
	描述： 	班级信息基础接口
]]
local _ClassService = {};

-- -------------------------------------------------------------------------
--[[
	局部函数：根据班级ID查询兄弟班级，不包含自己
	作者： 胡悦 2015-07-11
	参数：classId  班级ID
]]
local function getBrotherClassByClassId(self, classId)

	local classModel = require "base.class.model.ClassInfoModel";
  
	local classTable  = classModel: getBrotherClassByClassId(classId);
    if not classTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, class_list=classTable };

end

_ClassService.getBrotherClassByClassId = getBrotherClassByClassId;
-- -------------------------------------------------------------------------
return _ClassService;