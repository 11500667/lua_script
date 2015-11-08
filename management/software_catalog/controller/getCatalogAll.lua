
-- -----------------------------------------------------------------------------------
-- 描述：前台查询所有插件列表
-- 作者：刘全锋
-- 日期：2015年10月09日
-- -----------------------------------------------------------------------------------


local catalogModel = require "management.software_catalog.model.CatalogModel";

local result,returnjson     = catalogModel.queryCatalogAll();


if not result then
    local returnjson={};
    returnjson.success = false;
    returnjson.info = "查询信息失败！";
end

ngx.say(encodeJson(returnjson));
