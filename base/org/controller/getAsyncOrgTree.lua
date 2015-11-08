#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-04-22
#描述：获取组织机构树
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["org_id"] == nil or args["org_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数org_id不能为空！\"}");
    return;
elseif args["org_type"] == nil or args["org_type"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数org_type不能为空！\"}");
    return;
elseif args["get_next"] == nil or args["get_next"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数get_next不能为空！\"}");
    return;
end

local orgId      = tonumber(args["org_id"]);
local orgType    = tonumber(args["org_type"]);
local nextFlag   = tonumber(args["get_next"]); -- 0获取当前机构，1获取下级机构

local orgService = require "base.org.services.OrgService";
local resultObj  = orgService: getAsyncOrgTree(orgId, orgType, nextFlag);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJsonStr = cjson.encode(resultObj);
ngx.print(responseJsonStr);


