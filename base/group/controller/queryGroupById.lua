
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 根据Id查询群组
-- 作者：刘全锋
-- 日期：2015年8月6日
-- -----------------------------------------------------------------------------------

ngx.header.content_type = "text/plain";
local request_method = ngx.var.request_method;
local cjson = require "cjson";

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local groupId   = args["groupId"];
local app_type  = args["app_type"];--1 云版2 局版

if groupId == nil or groupId == "" then
    ngx.say("{\"success\":false,\"info\":\"groupId参数错误！\"}");
    return;
end

local groupModel = require "base.group.model.GroupModel";
local resultJsonObj  = groupModel.queryGroupById(groupId,app_type);

ngx.print(cjson.encode(resultJsonObj));





