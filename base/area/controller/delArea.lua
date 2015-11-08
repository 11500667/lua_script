--删除行政区划 级联删除 该行政区划下的组织和人员
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"


local area_id=args["area_id"]

local areaService = require "base.area.services.AreaService";
  
local result  = areaService: delArea(area_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))