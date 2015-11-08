--[[
#申健  2015-07-03
#描述：获取我的资源、我的试题、我的备课、我的微课、我的试卷下的tab标签分类
]]

local responseObj = {};

responseObj["success"]   = true;
responseObj["type_list"] = v_my_info_type;

local cjson = require "cjson";
ngx.print(cjson.encode(responseObj));