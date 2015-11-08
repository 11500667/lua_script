#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-09
#描述：获取教师用户的特殊功能列表
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

if args["person_id"] == nil or args["person_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
	return;	
elseif args["identity_id"] == nil or args["identity_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数identity_id不能为空！\"}");
	return;		
end

-- 单位ID
local personId 	  = tonumber(args["person_id"]);
local identityId  = tonumber(args["identity_id"]);

local CheckPerson = require "multi_check.model.CheckPerson";
local isCheckPerson, allowAddPerson = CheckPerson: isCheckPerson(personId, identityId);

local personMenuJson   = {};
personMenuJson.success = true;
-- 是否审核人员，对应功能[资源审核]
personMenuJson.isCheckPerson  = isCheckPerson;
-- 是否允许添加审核人员，对应功能[设置审核人员]
personMenuJson.allowAddPerson = allowAddPerson;

local cjson   = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(personMenuJson);

ngx.print(jsonStr);