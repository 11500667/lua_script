#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-6
#描述：保存用户的定制信息
]]
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["pageNumber"] == nil or args["pageNumber"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;
elseif not tonumber(args["pageNumber"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageNumber不合法！\"}");
	return;
elseif args["pageSize"] == nil or args["pageSize"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;
elseif not tonumber(args["pageSize"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageSize不合法！\"}");
	return;
elseif args["param_json"] == nil or args["param_json"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数param_json不能为空！\"}");
	return;
end

local pageNumber = args["pageNumber"];
local pageSize 	 = args["pageSize"];
local paramJson  = args["param_json"];
ngx.log(ngx.ERR, "===> 查询资源定制列表， 参数param_json：[<>]", paramJson, "[<>]");
local cjson		= require "cjson";
local paramObj	= cjson.decode(paramJson);

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local resultJson = ResourceCustomize: getCustomizeList(pageNumber, pageSize, paramObj);

cjson.encode_empty_table_as_object(false);
local resultJsonStr = cjson.encode(resultJson);
ngx.print(resultJsonStr);
