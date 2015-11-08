--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local cjson = require "cjson"
local preparationModel = require "yxx.preparation.model.Model";
local parameterUtil = require "yxx.tool.ParameterUtil";
--  获取request的参数
local yx_id = parameterUtil:getStrParam("yx_id","");
if string.len(yx_id)==0 then
    say("{\"success\":false,\"info\":\"yx_id参数错误！\"}")
    return
end
local return_json = preparationModel:getYxMaterialStat(yx_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_json);
say(responseJson);