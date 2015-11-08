
-- -----------------------------------------------------------------------------------
-- 描述：添加插件
-- 作者：刘全锋
-- 日期：2015年10月6日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local fieldTable = {};

local software_name		= args["software_name"];
local parent_id			= args["parent_id"];
local b_use     		= args["b_use"];
local pic_url		    = args["pic_url"];
local software_url		= args["software_url"];
local create_time		= os.date("%Y-%m-%d %H:%M:%S");
local software_content  = args["software_content"];
local px                = args["px"];
local software_explain  = args["software_explain"];

if software_name == nil or software_name == "" then
    ngx.say("{\"success\":false,\"info\":\"software_name参数错误！\"}");
    return;
end

if parent_id == nil or parent_id == "" then
    ngx.say("{\"success\":false,\"info\":\"parent_id参数错误！\"}");
    return;
end


if b_use == nil or b_use == "" then
    ngx.say("{\"success\":false,\"info\":\"b_use参数错误！\"}");
    return;
end

if px == nil or px == "" then
    ngx.say("{\"success\":false,\"info\":\"px参数错误！\"}");
    return;
end

if software_explain == nil then
    software_explain = "";
end

if pic_url == nil then
    pic_url = "";
end

if software_url == nil then
    software_url = "";
end

local catalogModel = require "management.software_catalog.model.CatalogModel";


fieldTable["software_name"]	    = software_name;
fieldTable["parent_id"]		    = parent_id;
fieldTable["b_use"]	            = b_use;
fieldTable["pic_url"]	        = pic_url;
fieldTable["software_url"]	    = software_url;
fieldTable["create_time"]	    = create_time;
fieldTable["software_content"]	= software_content;
fieldTable["px"]	            = px;
fieldTable["software_explain"]  = software_explain;

local result     = catalogModel.saveCatalog(fieldTable);
local responseJson = {}
responseJson["success"] = result;   
if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.say(encodeJson(responseJson));