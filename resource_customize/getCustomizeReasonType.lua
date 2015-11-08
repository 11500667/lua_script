#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-04-12
#描述：获取未通过原因
]]

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local reasonJson = ResourceCustomize: reason();

local resultObj = {};
resultObj.success = true;
resultObj.list 	  = reasonJson;

local cjson		= require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJsonStr = cjson.encode(resultObj);
ngx.log(ngx.ERR, "===> 查询资源定制的类型列表，返回的值：[<>]", resultJsonStr, "[<>]");
ngx.print(resultJsonStr);