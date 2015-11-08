-- 获取行政区划列表 by huyue 2015-08-19
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"

local area_name = args["area_name"]

local area_type=args["area_type"]

local parent_id=args["parent_id"]

local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]

local areaService = require "base.area.services.AreaService";

local result  = areaService: getAreaList(area_name,area_type,parent_id,pageNumber,pageSize);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
