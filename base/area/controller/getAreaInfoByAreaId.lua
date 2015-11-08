--根据area_id获取Area详情 by huyue 2015-08-22
local args = getParams();

--引用模块
local cjson = require "cjson"


local area_id = args["area_id"];

local areaService = require "base.area.services.AreaService";
  
local result  = areaService: getAreaInfoByAreaId(area_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
