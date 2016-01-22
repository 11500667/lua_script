-- -----------------------------------------------------------------------------------
-- 描述：试卷的业务实现类
-- 日期：2015年9月17日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local cacheUtil = require "common.CacheUtil";
local DBUtil    = require "common.DBUtil";
local SSDBUtil  = require "common.SSDBUtil";

local _PaperService = {}

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据paper_id_int获取试卷的信息
-- 日    期： 2015年10月30日
-- 参    数： paperIdChar 试卷的GUID
-- 返 回 值： 返回值信息
-- -----------------------------------------------------------------------------------
local function getPaperByIdIntAndGroup(self, paperIdInt, groupId)
    local sql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_INFO_SPHINXSE WHERE query=';filter=paper_id_int, " .. paperIdInt .. ";filter=group_id," .. groupId .. ";'";
    ngx.log(ngx.ERR, "[sj_log] -> [paper] -> sql : [", sql, "]");
    local paperRes, err = DBUtil: querySingleSql(sql);
    if not paperRes then
        error("通过sphinx查询试卷ID出错");
        return false;
    end
    local paperInfoId = paperRes[1]["ID"];
    local paperCache = cacheUtil: hmget("paper_" .. paperInfoId, "paper_id_int", "paper_id_char", "paper_name", "paper_type", "paper_page", "scheme_id", "structure_id", "structure_code", "parent_structure_name", "source_id", "file_id", "extension", "for_iso_url", "for_urlencoder_url", "preview_status", "json_content", "question_count", "person_id", "identity_id", "create_time", "ts", "group_id", "down_count", "resource_info_id", "b_delete", "stage_id", "subject_id", "paper_app_type", "paper_app_type_name");
    if not paperCache then
        error("\n\n获取试卷的缓存出错， paper_id_char:[" .. paperIdChar .. "]\n\n");
        return false;
    end
    local paperType = tonumber(paperCache["paper_type"]);
    if paperType == 2 then -- 非格式化试卷
        local resInfoId = paperCache["resource_info_id"]
        local resCache  = SSDBUtil: multi_hget_hash("resource_" .. resInfoId, "preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page");
        if not resCache then
            error("\n\n获取试卷对应的资源缓存出错， paper_id_char:[" .. paperIdChar .. "], resource_info_id: [" .. resInfoId .. "]\n\n");
        end
        paperCache["preview_status"]     = resCache["preview_status"];
        paperCache["for_iso_url"]        = resCache["for_iso_url"];
        paperCache["for_urlencoder_url"] = resCache["for_urlencoder_url"];
        paperCache["file_id"]            = resCache["file_id"];
        paperCache["url_code"]           = ngx.escape_uri(paperCache["paper_name"]);
        paperCache["resource_page"]      = resCache["resource_page"];
    end

    return paperCache;
end
_PaperService.getPaperByIdIntAndGroup = getPaperByIdIntAndGroup;

-- -----------------------------------------------------------------------------------
-- 函数描述： 根据试卷的 paper_id_char 获取试卷以及其中试题的详细信息
-- 日    期： 2015年9月17日
-- 作    者： 申健
-- 参    数： 无
-- 返 回 值： string类型：需要调用的函数名；如果获取失败，则返回nil；
-- -----------------------------------------------------------------------------------
local function getPaperDetailByIdChar(self, paperIdChar)
    local paperJsonStr = cacheUtil: hget("paperinfo_" .. paperIdChar, "json_content");
    if paperJsonStr == nil or paperJsonStr == "" then
        error("key：[paperinfo_" .. paperIdChar .. "] 的缓存中的 json_content 为空");
    end
    
    local paperObj = decodeJson(ngx.decode_base64(paperJsonStr));
    local subjectId = paperObj["subject_id"];
    local quesList = paperObj["ti"];

    -- 1、整理试卷的信息
    local paperInfo = {};
    paperInfo["paper_id_char"]       = paperIdChar;
    paperInfo["paper_name"]          = paperObj["paper_name"];
    paperInfo["subject_id"]          = subjectId; 
    paperInfo["scheme_id"]           = paperObj["scheme_id"]; 
    paperInfo["structure_id"]        = paperObj["structure_id"]; 
    paperInfo["paper_type"]          = paperObj["paper_type"]; 
    paperInfo["paper_app_type"]      = paperObj["paper_app_type"]; 
    paperInfo["paper_app_type_name"] = paperObj["paper_app_type_name"]; 

    -- 2、整理试卷中试题的信息
    local kgZgHash = {};

    if next(quesList) ~= nil then
        local quesIdCharArray = {};
        for index = 1, #quesList do
            local quesInfoId = quesList[index]["id"];
            local quesIdChar = cacheUtil: hget("question_" .. quesInfoId, "question_id_char");
            table.insert(quesIdCharArray, quesIdChar);
        end
        ngx.log(ngx.ERR, "[sj_log] -> [paperService] -> quesIdCharArray: [", encodeJson(quesIdCharArray), "]");
        -- 获取试题的id
        local quesZsdHash = {};
        local sql = "SELECT DISTINCT T1.QUESTION_ID_CHAR, T2.STRUCTURE_ID, T2.STRUCTURE_CODE, T2.STRUCTURE_NAME " .. 
                    "FROM T_TK_QUESTION_INFO T1 INNER JOIN T_RESOURCE_STRUCTURE T2 " .. 
                    "ON T1.STRUCTURE_ID_INT = T2.STRUCTURE_ID " ..
                    "WHERE T1.QUESTION_ID_CHAR in ('" .. table.concat(quesIdCharArray, "','") .. "')  AND T2.TYPE_ID=2 AND T2.IS_DELETE=0;";
        ngx.log(ngx.ERR, "[sj_log] -> [paperService] -> sql: [", sql, "]");
        local strucRes, err = DBUtil: querySingleSql(sql);
        for index, record in ipairs(strucRes) do
            local quesIdChar = record["QUESTION_ID_CHAR"];
            local tempStrucObj = {};
            tempStrucObj["structure_id"]   = record["STRUCTURE_ID"];
            tempStrucObj["structure_code"] = record["STRUCTURE_CODE"];
            tempStrucObj["structure_name"] = record["STRUCTURE_NAME"];
            
            local tempQuesZsdArray;
            if quesZsdHash[quesIdChar] == nil or quesZsdHash[quesIdChar] == ngx.null then
                tempQuesZsdArray = {};
                table.insert(tempQuesZsdArray, tempStrucObj);
                quesZsdHash[quesIdChar] = tempQuesZsdArray
            else
                table.insert(quesZsdHash[quesIdChar], tempStrucObj);
            end
        end

        ngx.log(ngx.ERR, "[sj_log] -> [paperService] -> quesZsdHash: [", encodeJson(quesZsdHash), "]");

        -- 组装试题列表数据
        local quesInfoList = {};
        for index = 1, #quesList do
            local quesInfoId    = quesList[index]["id"];
            local quesCacheObj  = cacheUtil: hmget("question_" .. quesInfoId, "id", "json_question", "json_answer");
            local jsonQuesObj   = decodeJson(ngx.decode_base64(quesCacheObj["json_question"]));
            ngx.log(ngx.ERR, "[sj_log] -> [paperService] -> ngx.decode_base64(quesCacheObj[\"json_answer\"]): [", ngx.decode_base64(quesCacheObj["json_answer"]), "]");

            

            local record                 = {};
            record["info_id"]            = quesInfoId;
            record["question_id_char"]   = jsonQuesObj["question_id_char"];
            record["file_id"]            = jsonQuesObj["t_id"];
            record["question_tips"]      = jsonQuesObj["t_title"];
            record["down_count"]         = quesCacheObj["down_count"];
            record["height"]             = quesCacheObj["height"];
            record["child_ques"]         = quesCacheObj["t_child"] or {};
            
            
            local quesTypeId             = jsonQuesObj["qt_id"];
            record["question_type_id"]   = quesTypeId;
            record["question_type_name"] = jsonQuesObj["qt_name"];

            local isKgZg;
            if kgZgHash[quesTypeId] == nil or kgZgHash[quesTypeId] == ngx.null then
                isKgZg = cacheUtil: hget("qt_list_" .. subjectId .. "_" .. quesTypeId, "qt_type");
                ngx.log(ngx.ERR, "[sj_log] -> [isKgZg] -> [", isKgZg, "]");
                if isKgZg ~= nil and isKgZg ~= ngx.null then
                    kgZgHash[quesTypeId] = isKgZg;
                else
                    kgZgHash[quesTypeId] = "2";
                    isKgZg = "2";
                end
            else
                isKgZg = kgZgHash[quesTypeId];
            end
            record["kg_zg"] = isKgZg;

            if tonumber(isKgZg) == 1 then -- 客观题
                local jsonAnswerStr = quesCacheObj["json_answer"];
                jsonAnswerStr = string.gsub(jsonAnswerStr, "77u/", "");
                ngx.log(ngx.ERR, "[********] ", jsonAnswerStr);
                jsonAnswerStr = ngx.decode_base64(jsonAnswerStr);
                local jsonAnswerObj = decodeJson(jsonAnswerStr);
                record["answer"]             = jsonAnswerObj["answer"];
                record["child_ques_answer"]  = jsonAnswerObj["t_child_answer"] or {};
            else
                if #record["child_ques"] > 0 then
                    local jsonAnswerStr = ngx.decode_base64(quesCacheObj["json_answer"]);
                    local jsonAnswerObj = decodeJson(jsonAnswerStr);
                    record["answer"]             = "";
                    record["child_ques_answer"]  = jsonAnswerObj["t_child_answer"] or {};
                else
                    record["answer"]             = "";
                    record["child_ques_answer"]  = {};
                end
            end
            
            record["difficult_id"]   = jsonQuesObj["nd_id"];
            record["difficult_star"] = jsonQuesObj["nd_star"];

            local optionCount = jsonQuesObj["option_count"];
            if optionCount == nil or optionCount == "" then
                optionCount = 0;
            end
            record["option_count"] = tonumber(optionCount);

            local strucId          = jsonQuesObj["structure_id"];
            record["structure_id"] = strucId;

            local schemeId         = cacheUtil: hget("t_resource_structure_" .. strucId, "scheme_id_int");
            record["scheme_id"]    = schemeId;

            local tempZsdArray = quesZsdHash[record["question_id_char"]];
            if tempZsdArray == nil or tempZsdArray == ngx.null then
                record["zsd_array"] = {};
            else
                record["zsd_array"] = tempZsdArray;
            end

            table.insert(quesInfoList, record);
        end
        paperInfo["question_list"] = quesInfoList;
    end

    return paperInfo;
end
_PaperService.getPaperDetailByIdChar = getPaperDetailByIdChar;

return _PaperService;