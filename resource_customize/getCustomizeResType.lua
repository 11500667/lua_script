#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-23
#描述：获取定制资源的类型
]]

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local typeJson = ResourceCustomize: getResType();

local resultObj = {};
resultObj.success = true;
resultObj.list 	  = typeJson;

local cjson		= require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJsonStr = cjson.encode(resultObj);
--ngx.log(ngx.ERR, "===> 查询资源定制的类型列表，返回的值：[<>]", resultJsonStr, "[<>]");
ngx.print(resultJsonStr);
