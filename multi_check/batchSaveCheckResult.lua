#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-12
#描述：批量审核资源
]]

--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["unit_id"] == nil or args["unit_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"参数unit_id不能为空！\"}");
	return;
elseif args["check_msg"] == nil or args["check_msg"]=="" then
	ngx.print("{\"success\":false,\"info\":\"参数check_msg不能为空！\"}");
	return;	
elseif args["param_json"] == nil or args["param_json"]=="" then
	ngx.print("{\"success\":false,\"info\":\"参数param_json不能为空！\"}");
	return;	
elseif args["person_id"] == nil or args["person_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"参数person_id不能为空！\"}");
	return;	
elseif args["identity_id"] == nil or args["identity_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
	return;	
end

local unitId  	  = tonumber(args["unit_id"]);
local checkMsg 	  = args["check_msg"];
local paramJson	  = args["param_json"];

-- 需要修改为从前台获取cookie
-- local personId 	 = tonumber(ngx.var.cookie_person_id);
-- local identityId  = tonumber(ngx.var.cookie_identity_id);
local personId 	 = tonumber(args["person_id"]);
local identityId = tonumber(args["identity_id"]);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

local checkArray = cjson.decode(paramJson);

local multiCheck = require "multi_check.model.MultiCheck";
local resultFlag, info  = multiCheck: batchCheck(unitId, checkArray, checkMsg, personId, identityId);
ngx.log(ngx.ERR, "===> 处理是否成功：", resultFlag, ", ===> 返回信息：", info);

local resultJsonObj = {};
resultJsonObj.success = resultFlag;
resultJsonObj.info    = info;

local jsonStr = cjson.encode(resultJsonObj);
ngx.print(jsonStr);



