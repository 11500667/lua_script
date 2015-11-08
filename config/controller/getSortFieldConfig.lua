--[[
#申健  2015-07-03
#描述：获取各个库下排序的字段的配置
]]

local responseObj = {};

responseObj["success"]   = true;
responseObj["sort_config"] = v_config_sort_field;

local cjson = require "cjson";
ngx.print(cjson.encode(responseObj));