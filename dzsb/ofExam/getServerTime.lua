#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-18
#描述：获取系统时间
]]
local currentServerTime = ngx.localtime();

local result = {};
result["success"] = true;
result["currentServerTime"] = currentServerTime;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
ngx.say(tostring(cjson.encode(result)));