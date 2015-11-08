--[[
	胡悦
	行政区划信息基础接口
]]

local _AreaService = {};

--[[
    描述：根据行政区划名称和行政区划类型查询行政区划
    作者： 胡悦 2015-08-19
    参数：    areaName,areaType
    返回值：存储结果的table
]]
local function getAreaList(self,areaName,areaType,parentId,pageNumber,pageSize)
	local areaModel = require "base.area.model.AreaModel";
	local areaTable = areaModel:getAreaList(areaName,areaType,parentId,pageNumber,pageSize);

  --  if not areaTable then
  --      return { success=false, info="获取数据失败" };
 --   end
    
	
	return areaTable;
 --   return { success=true, table_List=areaTable };

end

_AreaService.getAreaList = getAreaList;
---------------------------------------------------------------------------
--[[
    描述：新增行政区划
    作者： 胡悦 2015-08-19
]]
local function addArea(self,area_name,parent_id,area_type,area_code,created_by)
	local areaModel = require "base.area.model.AreaModel";
	local result = areaModel:addArea(area_name,parent_id,area_type,area_code,created_by);
	return result;
end
_AreaService.addArea = addArea;
---------------------------------------------------------------------------

--[[
    描述：获取当前行政区划下子节点
    作者： 姜旭 2015-08-21
]]
local function getChildArea(self , area_id)
	local areaModel = require "base.area.model.AreaModel";
	local result = areaModel:getChildArea(area_id,area_name,area_name_jc,parent_id,area_type,created_by);
	return result;
end
_AreaService.getAllChildArea = getAllChildArea;
---------------------------------------------------------------------------
--[[
	根据area_id 获取area信息

]]
local function getAreaInfoByAreaId(self,area_id)
	local areaModel = require "base.area.model.AreaModel";
	local result = areaModel:getAreaInfoByAreaId(area_id);
	return result;

end
_AreaService.getAreaInfoByAreaId = getAreaInfoByAreaId;
---------------------------------------------------------------------------

--[[
	根据area_id 获取行政区划树
]]
local function getAreaTree(self,area_id)
	local areaModel = require "base.area.model.AreaModel";
	local areaTable = areaModel:getAreaTree(area_id);
	 if not areaTable then
        return { success=false, info="获取数据失败" };
    end
	return { success=true, table_List=areaTable };
end
_AreaService.getAreaTree = getAreaTree;
---------------------------------------------------------------------------
--[[
	修改行政区划  胡悦  2015-09-02
]]
local function  modifyArea(self,area_id,area_name,area_code)
	local areaModel = require "base.area.model.AreaModel";
	local result = areaModel:modifyArea(area_id,area_name,area_code);
	return result;
end

_AreaService.modifyArea = modifyArea;
---------------------------------------------------------------------------
--[[
	修改行政区划  胡悦  2015-09-02
]]
local function  beforeDelArea(self,area_id)
	local areaModel = require "base.area.model.AreaModel";
	local result = areaModel:beforeDelArea(area_id);
	return result;
end

_AreaService.beforeDelArea = beforeDelArea;
---------------------------------------------------------------------------
--[[
	修改行政区划  胡悦  2015-09-02
]]
local function  delArea(self,area_id)
	local areaModel = require "base.area.model.AreaModel";
	local result = areaModel:delArea(area_id);
	return result;
end

_AreaService.delArea = delArea;
---------------------------------------------------------------------------
return _AreaService;