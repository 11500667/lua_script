--获取行政区划树 by huyue 2015-08-22 
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"


local area_id=args["area_id"]

local areaService = require "base.area.services.AreaService";
  
local result  = areaService: getAreaTree(area_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))