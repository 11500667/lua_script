
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 创建群组
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


local groupId		= args["groupId"];
local group_name	= args["group_name"];
local creator		= args["creator"];
local creator_id 	= ngx.var.cookie_person_id;
local identityId 	= ngx.var.cookie_identity_id;
local plat_type		= args["plat_type"];
local plat_id		= args["plat_id"];
local use_range		= args["use_range"];
local group_type	= args["group_type"];
local pageNumber	= args["pageNumber"];
local pageSize		= args["pageSize"];


if groupId == nil  then
	groupId = "";
end
if group_name == nil  then
	group_name = "";
end
if creator == nil  then
	creator = "";
end
if plat_type == nil  then
	plat_type = "";
end
if plat_id == nil  then
	plat_id = "";
end
if use_range == nil  then
	use_range = "";
end
if group_type == nil  then
	group_type = "";
end

if pageNumber == nil or pageNumber == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;	
end
if pageSize == nil or pageSize == "" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;		
end

local groupModel = require "base.group.model.GroupModel";


--[[其它检索条件暂时不用20150808
local result,returnjson     = groupModel.queryGroup(groupId, group_name, creator, creator_id, identityId, plat_type, plat_id, use_range, group_type, pageNumber, pageSize);
]]

if groupId == "" and group_name=="" and creator=="" then
	ngx.say("{\"success\":false,\"info\":\"参数错误！\"}");
	return;
end




local result,returnjson     = groupModel.queryGroup(keyWord, creator_id, identityId, pageNumber, pageSize);

if not result then 
	local returnjson={};
	returnjson.success = false;
	returnjson.info = "获取群组失败！";
end

ngx.print(encodeJson(returnjson));