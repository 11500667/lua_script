-- -----------------------------------------------------------------------------------
-- 描述：试卷接口 -- 根据试卷的guid获取试卷的详细信息，包含试卷和试卷中试题的信息
-- 日期：2015年9月16日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local cacheUtil    = require "common.CacheUtil";
local DBUtil       = require "common.DBUtil";
local paperService = require "paper.service.PaperService";

local paperIdChar = getParamByName("paper_id_char");
ngx.log(ngx.ERR, "[sj_log] -> paperIdChar: [", paperIdChar, "]");
if paperIdChar == nil or paperIdChar == "" then
    ngx.say("{\"success\":false,\"info\":\"参数paper_id_char不能为空\"}");
    return;
end

local resultObj = {};
local paperDetailObj = paperService: getPaperDetailByIdChar(paperIdChar);
resultObj["success"] = true;
resultObj["paper_detail"] = paperDetailObj;
ngx.print(encodeJson(resultObj));