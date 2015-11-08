--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say;
local cjson = require "cjson";
local StatModel = require "yxx.main.statistics.model.StatModel";
local json = StatModel:wk_count();
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(json);
say(responseJson);
