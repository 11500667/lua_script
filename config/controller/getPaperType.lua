--[[
#申健  2015-07-03
#描述：获取试卷类型的配置信息
]]

local responseObj = {};

responseObj["success"]   = true;
responseObj["type_list"] = v_config_paper_type;

local cjson = require "cjson";
ngx.print(cjson.encode(responseObj));