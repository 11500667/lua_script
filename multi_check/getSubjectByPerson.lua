#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-09
#描述：获取审核人员在指定单位下可以审核的科目
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
	ngx.print("{\"success\":\"false\",\"info\":\"参数unit_id不能为空！\"}");
	return;
elseif args["person_id"] == nil or args["person_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
	return;	
elseif args["identity_id"] == nil or args["identity_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数identity_id不能为空！\"}");
	return;		
end

-- 单位ID
local unitId 	  = tonumber(args["unit_id"]);
local personId 	  = tonumber(args["person_id"]);
local identityId  = tonumber(args["identity_id"]);

local CheckPerson = require "multi_check.model.CheckPerson";
local subjectJson = CheckPerson: getSubjectByPerson(unitId, personId, identityId);

local cjson   = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(subjectJson);

ngx.print(jsonStr);
