--
-- 试题的相关接口的基础函数
-- User: 申健
-- Date: 2015/5/4
-- Time: 14:03
--

local _QuestionBase = {};

-- -------------------------------------------------------------------------

--
-- Desc: 获取试题的基础信息（包括知识点的ID）
-- User: 申健
-- Date: 2015/5/4
-- Time: 14:03
--
local function getQuesDetailByIdChar(self, quesInfoId)

    local CacheUtil = require "multi_check.model.CacheUtil";
    local cache     = CacheUtil: getRedisConn();

    local result, err = cache: hget("question_" .. quesInfoId, "question_id_char");
    if not result or result == ngx.null then
        CacheUtil: keepConnAlive(cache);
        ngx.log(ngx.ERR, "===> [[[ (缓存中)无法通过试题在T_TK_QUESTION_INFO表的ID-> [", quesInfoId, "]获取question_id_char ]]] <===");
        return false;
    end

    local quesIdChar = result;

    local sql = "SELECT DISTINCT IFNULL(T1.QUESTION_ANSWER, '') AS QUESTION_ANSWER, IFNULL(T1.QUESTION_TYPE_ID, 0) AS QUESTION_TYPE_ID, IFNULL(T1.QUESTION_TYPE_NAME, '') AS QUESTION_TYPE_NAME, IFNULL(T1.QUESTION_DIFFICULT_ID, 3) AS QUESTION_DIFFICULT_ID, IFNULL(T1.QUESTION_DIFFICULT_NAME, '中') AS QUESTION_DIFFICULT_NAME, IFNULL(T1.QUESTION_DIFFICULT_STAR, '★★★') AS QUESTION_DIFFICULT_STAR, T4.QT_TYPE AS KG_ZG, T1.FILE_ID, T1.QUESTION_TIPS, T1.OPTIONS_COUNT, T3.STRUCTURE_ID, T3.SCHEME_ID_INT, T3.STRUCTURE_NAME, T3.STRUCTURE_CODE " ..
    "FROM T_TK_QUESTION_BASE T1 INNER JOIN T_TK_QUESTION_INFO T2 ON T1.QUESTION_ID_CHAR = T2.QUESTION_ID_CHAR AND (T2.GROUP_ID=1 OR T2.GROUP_ID=2) " ..
    "LEFT OUTER JOIN T_RESOURCE_STRUCTURE T3 ON T2.STRUCTURE_ID_INT = T3.STRUCTURE_ID AND T3.TYPE_ID=2 " ..
    "LEFT OUTER JOIN T_TK_QUESTION_TYPE T4 ON T1.QUESTION_TYPE_ID = T4.QT_ID " .. 
    "WHERE T1.QUESTION_ID_CHAR='" .. quesIdChar .. "';";

	-- ngx.log(ngx.ERR, "===> 查询试题详细信息的sql语句： [[[", sql, "]]]");
	
    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return false;
    end

    local resultTable = {};
    local zsdTable    = {};
    local zsdIdStr    = "";
    local zsdCodeStr  = "";
    local zsdNameStr  = "";
    for i = 1, #queryResult do

        local record = queryResult[i];
        if i == 1 then
            resultTable["question_id_char"]   = quesIdChar;
            resultTable["question_answer"]    = record["QUESTION_ANSWER"];
            resultTable["question_type_id"]   = record["QUESTION_TYPE_ID"];	     --试题类型名称
            resultTable["question_type_name"] = record["QUESTION_TYPE_NAME"];    --试题类型名称
            resultTable["nd_id"]              = record["QUESTION_DIFFICULT_ID"]; -- 难度名称
            resultTable["nd_name"]            = record["QUESTION_DIFFICULT_NAME"];
            resultTable["nd_star"]            = record["QUESTION_DIFFICULT_STAR"];
            resultTable["kg_zg"]              = record["KG_ZG"];
            resultTable["file_id"]            = record["FILE_ID"];
            resultTable["question_tips"]      = record["QUESTION_TIPS"];
            resultTable["options_count"]      = record["OPTIONS_COUNT"];
        end
        local zsdObj = {};
		if record["STRUCTURE_ID"] ~= nil and record["STRUCTURE_ID"] ~= ngx.null and record["STRUCTURE_ID"] ~= "" then
	        zsdObj["structure_id_int"] = record["STRUCTURE_ID"];
            zsdObj["structure_name"]   = record["STRUCTURE_NAME"];
	        zsdObj["structure_code"]   = record["STRUCTURE_CODE"];
	        table.insert(zsdTable, zsdObj);

            zsdIdStr   = zsdIdStr   .. "," .. tostring(record["STRUCTURE_ID"]);
            zsdNameStr = zsdNameStr .. "," .. record["STRUCTURE_NAME"];
            zsdCodeStr = zsdCodeStr .. "," .. record["STRUCTURE_CODE"];
		end
    end
    if #zsdIdStr > 0 then
	    zsdIdStr = zsdIdStr .. ",";
	end

	if #zsdNameStr > 1 then -- 去掉逗号
		zsdNameStr = string.sub(zsdNameStr, 2);
	end

    if #zsdCodeStr > 0 then
        zsdCodeStr = zsdCodeStr .. ",";
    end
	
    resultTable.knowledge_point_ids   = zsdIdStr;
    resultTable.knowledge_point_names = zsdNameStr;
    resultTable.knowledge_point_codes = zsdCodeStr;
    resultTable.knowledge_point_list  = zsdTable;

    local cjson = require "cjson";

    if resultTable.nd_name == nil then

        ngx.log(ngx.ERR, "[sj_log] -> [questionBase] -> resultTable 的值：[", cjson.encode(resultTable), "]");
    end

    return resultTable;

end

_QuestionBase.getQuesDetailByIdChar = getQuesDetailByIdChar;

-- -------------------------------------------------------------------------

return _QuestionBase;

