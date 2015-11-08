
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 验证创建群组创建数不能超过10个
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
--ngx.log(ngx.ERR, "cxg_log creator_id=====>"..creator_id.."==>");	
if creator_id == nil or creator_id == "" then
    ngx.say("{\"success\":false,\"info\":\"获取参数错误！\"}");
    return;
end

local plat_type		= args["plat_type"];

if plat_type == nil or plat_type == "" then
    ngx.say("{\"success\":false,\"info\":\"platTp参数错误！\"}");
    return;
end



local groupModel = require "base.group.model.GroupModel";
--验证群组最多创建10个
local result     = groupModel.chkGruopNum(creator_id , plat_type);
if result == false  then
    ngx.say("{\"success\":false,\"info\":\"云备课中心每个用户最多创建10个群组！\"}");
    return;
else
	ngx.say("{\"success\":true,\"info\":\"操作成功！\"}");
	return;
end

