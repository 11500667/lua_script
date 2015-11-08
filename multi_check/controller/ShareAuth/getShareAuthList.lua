#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-05-25
#描述：获取共享权限列表
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
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
    ngx.print("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
    return; 
elseif args["pageSize"] == nil or args["pageSize"]=="" then
    ngx.print("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
    return;     
end

-- 单位ID
local unitId     = tonumber(args["unit_id"]);
local pageNumber = tonumber(args["pageNumber"]);
local pageSize   = tonumber(args["pageSize"]);

local shareAuthModel = require "multi_check.model.ShareAuth";
local personJson     = shareAuthModel: getShareAuthList(unitId, pageNumber, pageSize);

local cjson   = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(personJson);

ngx.print(jsonStr);
