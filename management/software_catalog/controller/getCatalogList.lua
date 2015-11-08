
-- -----------------------------------------------------------------------------------
-- 描述：后台查询插件列表
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


local pageNumber = args["pageNumber"];
local pageSize   = args["pageSize"];
local parent_id  = args["parent_id"];


-- 判断是否有parent_id参数
if parent_id==nil or parent_id =="" then
    ngx.say("{\"success\":false,\"info\":\"parent_id参数错误！\"}")
    return
end


-- 判断是否有pageNumber参数
if pageNumber==nil or pageNumber =="" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end


-- 判断是否有pageSize参数
if pageSize == nil or pageSize =="" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end

local catalogModel = require "management.software_catalog.model.CatalogModel";

local result,returnjson     = catalogModel.queryCatalog(parent_id,pageNumber,pageSize);

if not result then
    local returnjson={};
    returnjson.success = false;
    returnjson.info = "查询信息失败！";
end

ngx.say(encodeJson(returnjson));
