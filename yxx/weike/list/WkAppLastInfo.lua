--[[
@Author cuijinlong
@date 2015-6-17
--]]
local cjson = require "cjson"
local WkModel = require "yxx.weike.model.WkModel";
--学生获得我的错题列表
local return_list = WkModel:app_last_info();
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_list);
ngx.say(responseJson);