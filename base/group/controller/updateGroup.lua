
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 修改群组
-- 作者：刘全锋
-- 日期：2015年8月6日
-- -----------------------------------------------------------------------------------

ngx.header.content_type = "text/plain";
local request_method = ngx.var.request_method;
local groupModel = require "base.group.model.GroupModel";

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local fieldTable = {};

local id				= args["id"];
local group_name		= args["group_name"];
local group_desc		= args["group_desc"];
local avater_url		= args["avater_url"];

local creator_id	= tostring(ngx.var.cookie_person_id);


if id == nil or id == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}");
    return;
end

if group_name == nil or group_name == "" then
    ngx.say("{\"success\":false,\"info\":\"group_name参数错误！\"}");
    return;
end

if avater_url == nil or avater_url == "" then
    ngx.say("{\"success\":false,\"info\":\"avater_url参数错误！\"}");
    return;
end


fieldTable["id"]			= id;
fieldTable["group_name"]	= group_name;
fieldTable["group_desc"]	= group_desc;
fieldTable["avater_url"]	= avater_url;


local result     = groupModel.updateGruop(fieldTable);

local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.print(encodeJson(responseJson));