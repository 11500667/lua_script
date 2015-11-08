
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 查询我的人员群组，适用移动端
-- 作者：陈续刚
-- 日期：2015年8月24日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local person_id	   = args["person_id"];
local ip_addr	   = args["ip_addr"];
local identity_id  = args["identity_id"];
local app_type     = args["app_type"];--1 云版2 局版

if person_id == nil or person_id == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数 person_id 不能为空！\"}");
	return;	
end
if identity_id == nil or identity_id == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数 identity_id 不能为空！\"}");
	return;		
end
if ip_addr == nil or ip_addr == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数 ip_addr 不能为空！\"}");
	return;		
end
if app_type == nil or app_type == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数 app_type 不能为空！\"}");
	return;		
end

local groupModel = require "base.group.model.GroupModel";

local result,returnjson     = groupModel.queryMyGroupForApp(ip_addr,person_id, identity_id,app_type);

if not result then 
	local returnjson={};
	returnjson.success = false;
	returnjson.info = "获取群组失败！";
end

ngx.print(encodeJson(returnjson));