
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 查询群组名称是否重复
-- 作者：刘全锋
-- 日期：2015年8月6日
-- -----------------------------------------------------------------------------------

ngx.header.content_type = "text/plain";
local request_method = ngx.var.request_method;

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local creator_id	= tostring(ngx.var.cookie_person_id);

if creator_id == nil or creator_id == "" then
    ngx.say("{\"success\":false,\"info\":\"获取参数错误！\"}");
    return;
end

local group_name		= args["group_name"];
local group_id		= args["group_id"];

if group_name == nil or group_name == "" then
    ngx.say("{\"success\":false,\"info\":\"group_name参数错误！\"}");
    return;
end



local groupModel = require "base.group.model.GroupModel";
--验证群组名是重复或与组织表中的名字重复
local result     = groupModel.chkGruopName(creator_id , group_name,group_id);
if result == false  then
    ngx.say("{\"success\":false,\"info\":\"群组名称错误！\"}");
    return;
else
	ngx.say("{\"success\":true,\"info\":\"操作成功！\"}");
	return;
end

