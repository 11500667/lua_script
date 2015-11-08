--初始化行政区划 by huyue 2015-08-19
--新增行政区划 by huyue 2015-08-19
local args = getParams();

--引用模块
local cjson = require "cjson"
local areaService = require "base.area.services.AreaService";
local areaModel = require "base.area.model.AreaModel";

local result= areaService:getAreaList("","");
area_list = result["table_List"];

for index=1,#area_list do 

	local area_id = area_list[index]["AREA_ID"];
	local area_name= area_list[index]["AREA_NAME"];
	local area_type =area_list[index]["AREA_TYPE"];
	local pareant_id = area_list[index]["PARENT_ID"];
	local addEducationBureauResult = areaModel:addEducationBureau(area_id,area_name,area_type,pareant_id);
	local org_id;
	if addEducationBureauResult.success then 
		org_id = addEducationBureauResult.org_id;	
	else 
		result=addEducationBureauResult;
	end
	
	--4插入行政区划管理员
	local addAreaAdminResult = areaModel:addAreaAdmin(area_id,area_name,area_type,org_id);
	--5插入教育局管理员
	local addEducationBureauAdminResult= areaModel:addEducationBureauAdmin(area_id,area_name,area_type,org_id);


end

local res={};
--res.area_list = area_list;
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(res))