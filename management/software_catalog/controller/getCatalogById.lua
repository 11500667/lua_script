
-- -----------------------------------------------------------------------------------
-- 描述：根据id查询插件
-- 作者：刘全锋
-- 日期：2015年10月6日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method

local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local catalogId  = args["catalogId"];


-- 判断是否有catalogId参数
if catalogId==nil or catalogId =="" then
    ngx.say("{\"success\":false,\"info\":\"catalogId参数错误！\"}")
    return
end



local catalogModel = require "management.software_catalog.model.CatalogModel";

local result   = catalogModel.queryCatalogById(catalogId);

if not result then
    result.success = false;
    result.info = "获取信息失败！";
end

ngx.say(encodeJson(result));
