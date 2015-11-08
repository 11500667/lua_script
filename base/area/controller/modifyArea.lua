--修改行政区划 by huyue 2015-09-02
local args = getParams();

--引用模块
local cjson = require "cjson"

--国标码
local area_code = args["area_code"];
if area_code == nil or area_code == "" then
	ngx.say("{\"success\":false,\"info\":\"area_code参数错误！\"}");
	return;
else
  area_code = args["area_code"];
end

--行政区划名称
local area_name = args["area_name"];
if area_name == nil or area_name == "" then
	ngx.say("{\"success\":false,\"info\":\"area_name参数错误！\"}");
	return;
else
  area_name = args["area_name"];
end

local area_id = args["area_id"];
if area_id == nil or area_id == "" then
	ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}");
	return;
else
  area_id = args["area_id"];
end

local areaService = require "base.area.services.AreaService";
  
local result  = areaService:modifyArea(area_id,area_name,area_code);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))