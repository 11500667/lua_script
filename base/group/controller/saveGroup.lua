
-- -----------------------------------------------------------------------------------
-- 描述：群组功能 -> 创建群组
-- 作者：刘全锋
-- 日期：2015年8月6日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local cjson = require "cjson"

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local fieldTable = {};


local parent_type		= args["parent_type"];
local parent_id			= args["parent_id"];
local group_name		= args["group_name"];
local group_type		= args["group_type"];
local use_range			= args["use_range"];
local plat_type			= args["plat_type"];
local plat_id			= args["plat_id"];
local group_desc		= args["group_desc"];
local b_request			= args["b_request"];
local avater_url		= args["avater_url"];



if parent_type == nil or parent_type == "" then
    ngx.say("{\"success\":false,\"info\":\"parent_type参数错误！\"}");
    return;
end

if parent_id == nil or parent_id == "" then
    ngx.say("{\"success\":false,\"info\":\"parent_id参数错误！\"}");
    return;
end


if group_name == nil or group_name == "" then
    ngx.say("{\"success\":false,\"info\":\"group_name参数错误！\"}");
    return;
end

if group_type == nil or group_type == "" then
    ngx.say("{\"success\":false,\"info\":\"group_type参数错误！\"}");
    return;
end


if use_range == nil or use_range == "" then
    ngx.say("{\"success\":false,\"info\":\"use_range参数错误！\"}");
    return;
end


if plat_type == nil or plat_type == "" then
    ngx.say("{\"success\":false,\"info\":\"plat_type参数错误！\"}");
    return;
end


if plat_id == nil or plat_id == "" then
    ngx.say("{\"success\":false,\"info\":\"plat_id参数错误！\"}");
    return;
end


if avater_url == nil or avater_url == "" then
    ngx.say("{\"success\":false,\"info\":\"avater_url参数错误！\"}");
    return;
end


local groupModel = require "base.group.model.GroupModel";


--验证云备课中心每个用户最多创建10个群组
if plat_type == 1 then
	local result     = groupModel.chkGruopNum(ngx.var.cookie_person_id , plat_type);
	if result == false  then
		ngx.say("{\"success\":false,\"info\":\"云备课中心每个用户最多创建10个群组！\"}");
		return;
	end
end


fieldTable["parent_type"]	= parent_type;
fieldTable["parent_id"]		= parent_id;
fieldTable["group_name"]	= group_name;
fieldTable["group_type"]	= group_type;
fieldTable["creator_id"]	= tostring(ngx.var.cookie_person_id);
fieldTable["master_id"]		= tostring(ngx.var.cookie_person_id);
fieldTable["use_range"]		= use_range;
fieldTable["plat_type"]		= plat_type;
fieldTable["plat_id"]		= plat_id;
fieldTable["group_desc"]	= group_desc;
fieldTable["create_time"]	= os.date("%Y-%m-%d %H:%M:%S");
fieldTable["avater_url"]	= avater_url;
fieldTable["identityId"]	= tostring(ngx.var.cookie_identity_id);
--fieldTable["bureau_id"]		= bureau_id;


local result     = groupModel.saveGroup(fieldTable);

local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.say(cjson.encode(responseJson));