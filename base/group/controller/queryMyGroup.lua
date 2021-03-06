
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 查询我的群组
-- 作者：刘全锋
-- 日期：2015年8月6日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local creator_id = ngx.var.cookie_person_id;
local identityId = ngx.var.cookie_identity_id;


local pageNumber	= args["pageNumber"];
local pageSize		= args["pageSize"];

if pageNumber == nil or pageNumber == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;	
end
if pageSize == nil or pageSize == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;		
end

local groupModel = require "base.group.model.GroupModel";

local result,returnjson     = groupModel.queryMyGroup(creator_id, identityId, pageNumber, pageSize);

if not result then 
	local returnjson={};
	returnjson.success = false;
	returnjson.info = "获取群组失败！";
end

ngx.print(encodeJson(returnjson));