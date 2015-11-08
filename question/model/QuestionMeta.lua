--[[
	作者： 	申健
	时间：	2015-04-07
	描述：	试题基础数据的接口
]]

local _QuestionMeta = {};


-----------------------------------------------------------------------------
--[[
	描述：获取试题难度列表
]]

local function getDifficultList(self)

    local sql = "SELECT TYPE_ID, SHOW_STYLE, TYPE_NAME FROM T_TK_DIFFICULT WHERE B_USE=1 ORDER BY COLUMN_SORT";

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(sql);

    local resultTable = {};
    for index = 1, #queryResult do
        
        local record    = queryResult[index];
        local item      = {};

        item["nd_id"]   = record["TYPE_ID"];
        item["nd_star"] = record["SHOW_STYLE"];
        item["nd_name"] = record["TYPE_NAME"];

        table.insert(resultTable, item);
    end

    return resultTable;
end

_QuestionMeta.getDifficultList = getDifficultList;

-----------------------------------------------------------------------------

return _QuestionMeta;