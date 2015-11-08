
-- -----------------------------------------------------------------------------------
-- 描述：插件列表管理 -> 删除插件
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


local catalogId		= args["catalogId"];



if catalogId == nil or catalogId == "" then
    ngx.say("{\"success\":false,\"info\":\"catalogId参数错误！\"}");
    return;
end


local catalogModel = require "management.software_catalog.model.CatalogModel";


local result     = catalogModel.deleteCatalog(catalogId);

local responseJson = {}
responseJson["success"] = result;
if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.say(encodeJson(responseJson));