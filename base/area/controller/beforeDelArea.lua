--删除行政区划前的验证 by huyue 2015-09-09
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"


local area_id=args["area_id"]

local areaService = require "base.area.services.AreaService";
  
local result  = areaService: beforeDelArea(area_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))