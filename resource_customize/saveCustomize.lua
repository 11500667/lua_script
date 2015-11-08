#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-6
#描述：保存用户的定制信息
]]

local personId = tostring(ngx.var.cookie_person_id)
local identityId = tostring(ngx.var.cookie_identity_id)

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["param_json"] == nil or args["param_json"]=="" then
	ngx.say(ngx.ERR, "{\"success\":\"false\",\"info\":\"参数param_json不能为空！\"}");
	return;
end

local paramJson = args["param_json"];
ngx.log(ngx.ERR, "===> 保存资源定制， 参数param_json：[<>]", paramJson, "[<>]");
local cjson		= require "cjson";

local paramObj	= cjson.decode(paramJson);

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";

local result, info = ResourceCustomize: saveCustomizeInfo(paramObj);

local responseObj = {};
responseObj.success = result;
responseObj.info	= info;

ngx.print(cjson.encode(responseObj));

