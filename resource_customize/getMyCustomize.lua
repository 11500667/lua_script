#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-4-13
#描述：获取用户的定制信息
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

if args["person_id"] == nil or args["person_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
	return;	
elseif args["identity_id"] == nil or args["identity_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数identity_id不能为空！\"}");
	return;		

elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
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
end

local pageNumber = args["pageNumber"];
local pageSize 	 = args["pageSize"];
-- 教师ID
local personId 	  = tonumber(args["person_id"]);
local identityId  = tonumber(args["identity_id"]);

local cjson		= require "cjson";
cjson.encode_empty_table_as_object(false);

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local resultJson, info = ResourceCustomize: getMyCustomizeList(pageNumber, pageSize, personId, identityId);

ngx.print(cjson.encode(resultJson));




