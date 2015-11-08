--
-- 学情分析 -> 统计函数的基础接口
-- User: 申健
-- Date: 2015/5/5
-- Time: 8:26
--

local _AnalyseData = {};

-- ----------------------------------------------------------------------------------------------
--[[
    描述：   插入学情分析的统计数据
    参数：   dataTable       存储数据的table对象
    返回值： true保存成功，fasle保存失败
]]
local function insertData(self, dataTable)
    
    local insertSql    = "INSERT INTO T_ANALYSE_STUDY_STATE (" .. 
    "SUBJECT_ID, CLASS_ID, KNOWLEDGE_POINT_ID, KNOWLEDGE_POINT_NAME, QUESTION_ID_CHAR, " .. 
    "STUDENT_ID, STUDENT_NAME, SEX_ID, TOTAL_COUNT, RIGHT_COUNT, WRONG_COUNT, CREATE_TIME" .. 
    ") VALUES (" .. 
    dataTable.subject_id .. "," .. 
    dataTable.class_id .. "," .. 
    dataTable.knowledge_point_id .. "," .. 
    ngx.quote_sql_str(dataTable.knowledge_point_name) .. "," .. 
    ngx.quote_sql_str(dataTable.question_id_char) .. "," ..
    dataTable.student_id .. "," .. 
    ngx.quote_sql_str(dataTable.student_name) .. "," ..
    dataTable.sex_id .. "," ..
    dataTable.total_count .. "," ..
    dataTable.right_count .. "," ..
    dataTable.wrong_count .. "," ..
    "NOW() );" ;

    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> ===> 保存学情分析统计数据的SQL语句：[[[", insertSql, "]]]");

    local  DBUtil       = require "common.DBUtil";
    local  insertResult = DBUtil: querySingleSql(insertSql);
    if not insertResult then
        return false;
    end
    -- 插入语句的返回值：类型table，格式：{"insert_id":770862,"server_status":11,"warning_count":0,"affected_rows":1}
    -- local topicId = insertResult["insert_id"];
    return true;
    
end
_AnalyseData.insertData = insertData;

-- ----------------------------------------------------------------------------------------------
--[[
    描述：  按班级统计学情
    参数：  subjectId       科目ID
    参数：  teacherId       教师ID
    参数：  classId         班级ID
    参数：  studentName     学生姓名
    参数：  startTime       开始时间
    参数：  endTime         结束时间
    返回值：table对象，存储查询结果和分页信息
]]
local function analyseByClass(self, subjectId, teacherId, classId, studentName, startTime, endTime, sortField, sortType)
    
    
    local segmentWhere = "";        
    local segmentClass = "";
    -- sql 的条件片段
    local segmentClass = self: getSqlClassSegment(classId, subjectId, teacherId);
    if segmentClass ~= "" then
        segmentWhere = segmentWhere .. segmentClass;
    end
    segmentWhere = segmentWhere .. " AND SUBJECT_ID=" .. subjectId;
    
    local segmentKey = "";
    if studentName ~= nil and studentName ~= "" then        
        segmentKey =  " AND T1.STUDENT_NAME LIKE '%" .. studentName .. "%'";
    end
                
    if startTime ~= nil and startTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME > '" .. startTime .. "'";
    end
    
    if endTime ~= nil and endTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME < '" .. endTime .. "'";
    end

    local segementSort = "";
    if sortField ~= nil and sortField ~= "" and sortType ~= nil and sortType ~= "" then
        local sortFieldTable = { 
            total_count   = "TOTAL_COUNT_SUM", 
            wrong_count   = "WRONG_COUNT_SUM", 
            right_count   = "RIGHT_COUNT_SUM",
            knowledge_point_count = "KNOWLEDGE_POINT_COUNT"
        };
        segementSort = segementSort .. " ORDER BY " .. sortFieldTable[sortField] .. " " .. ((sortType==1 and "ASC") or "DESC");
    else
        segementSort = segementSort .. " ORDER BY KNOWLEDGE_POINT_COUNT DESC";
    end

    local querySql = "SELECT T1.CLASS_ID, T3.CLASS_NAME, T1.STUDENT_ID, T1.STUDENT_NAME, " .. 
                    "IFNULL(TEMP.TOTAL_COUNT_SUM, 0) AS TOTAL_COUNT_SUM, " .. 
                    "IFNULL(TEMP.RIGHT_COUNT_SUM, 0) AS RIGHT_COUNT_SUM, " .. 
                    "IFNULL(TEMP.WRONG_COUNT_SUM, 0) AS WRONG_COUNT_SUM, " .. 
                    "IFNULL(TEMP.KNOWLEDGE_POINT_COUNT, 0) AS KNOWLEDGE_POINT_COUNT " .. 
                    " FROM T_BASE_STUDENT T1 LEFT OUTER JOIN ( " .. 
                    "SELECT STUDENT_ID, STUDENT_NAME, " .. 
                      "SUM(TOTAL_COUNT) AS TOTAL_COUNT_SUM, " .. 
                      "SUM(WRONG_COUNT) AS WRONG_COUNT_SUM, " .. 
                      "SUM(RIGHT_COUNT) AS RIGHT_COUNT_SUM, " .. 
                      "COUNT(DISTINCT KNOWLEDGE_POINT_ID) AS KNOWLEDGE_POINT_COUNT " .. 
                    "FROM T_ANALYSE_STUDY_STATE  " .. 
                    "WHERE  " .. segmentWhere .. 
                    " GROUP BY STUDENT_ID " .. 
                    ") TEMP ON T1.STUDENT_ID = TEMP.STUDENT_ID " .. 
                    "INNER JOIN T_BASE_CLASS T3 ON T1.CLASS_ID = T3.CLASS_ID " .. 
                    "WHERE T1." .. segmentClass .. segmentKey .. segementSort ;
    
    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> ===> 按班级进行统计的sql语句 ： [[[", querySql, "]]]");
    
    local  DBUtil      = require "common.DBUtil";
    local  queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return false;
    end
    
    local resultTable = {}
    for index=1, #queryResult do
        local record     = queryResult[index];
        local tempRecord = {};
        
        tempRecord["student_id"]            = record["STUDENT_ID"];
        tempRecord["student_name"]          = record["STUDENT_NAME"];
        tempRecord["class_id"]              = record["CLASS_ID"];
        tempRecord["class_name"]            = record["CLASS_NAME"];
        tempRecord["total_count"]           = record["TOTAL_COUNT_SUM"];
        tempRecord["right_count"]           = record["RIGHT_COUNT_SUM"];
        tempRecord["wrong_count"]           = record["WRONG_COUNT_SUM"];
        tempRecord["knowledge_point_count"] = record["KNOWLEDGE_POINT_COUNT"];
        
        table.insert(resultTable, tempRecord);
    end
    
    return resultTable;
end

_AnalyseData.analyseByClass = analyseByClass;

-- ----------------------------------------------------------------------------------------------
--[[
    描述：  按学生统计知识点的个人错误率和班级错误率
    参数：  subjectId       科目ID
    参数：  classId         班级ID
    参数：  startTime       开始时间
    参数：  endTime         结束时间
    参数：  studentId       当前页数
    参数：  pageNumber      当前页数
    参数：  pageSize        每页显示的记录条数
    参数：  sortField       排序字段
    参数：  sortType        1升序，2降序
    返回值：table对象，存储查询结果和分页信息
]]
local function analyseWrongPreByStudent(self, subjectId, classId, teacherId, studentId, startTime, endTime, pageNumber, pageSize, sortField, sortType)
    
    local  DBUtil      = require "common.DBUtil";
    local conditionSegment = "";
    -- sql 的条件片段
    local segmentClass = self: getSqlClassSegment(classId, subjectId, teacherId);
    if segmentClass ~= "" then
        conditionSegment = conditionSegment .. " AND " .. segmentClass;
    end

    if startTime ~= nil and startTime ~= "" then
        conditionSegment = conditionSegment .. " AND CREATE_TIME > '" .. startTime .. "'";
    end
    
    if endTime ~= nil and endTime ~= "" then
        conditionSegment = conditionSegment .. " AND CREATE_TIME < '" .. endTime .. "'";
    end
    
    -- sql 的排序片段
    local sortSegment = "";
    local sortFieldTable = { self_wrong_precent = "SELF_WRONG_PRECENT", class_wrong_precent = "WRONG_PRECENT" };
    if sortField ~= nil and sortField ~= "" and sortType ~= nil and sortType ~= "" then
        sortSegment = " ORDER BY " .. sortFieldTable[sortField] .. ((sortType == 1 and " ASC") or " DESC");
    else
        sortSegment = " ORDER BY SELF_WRONG_PRECENT DESC";
    end
    
    -- sql 的主体片段
    local querySql = "SELECT T1.KNOWLEDGE_POINT_ID, T1.KNOWLEDGE_POINT_NAME, T1.SELF_WRONG_PRECENT, T2.WRONG_PRECENT FROM " ..
        " (SELECT KNOWLEDGE_POINT_ID, KNOWLEDGE_POINT_NAME, TRUNCATE(SUM(WRONG_COUNT)/SUM(TOTAL_COUNT), 2) AS SELF_WRONG_PRECENT " ..
        " FROM  T_ANALYSE_STUDY_STATE " .. 
        " WHERE STUDENT_ID=" .. studentId .. " AND SUBJECT_ID=" .. subjectId .. conditionSegment .. " GROUP BY KNOWLEDGE_POINT_ID ) AS T1 " ..
        " INNER JOIN (SELECT KNOWLEDGE_POINT_ID, KNOWLEDGE_POINT_NAME, TRUNCATE(SUM(WRONG_COUNT)/SUM(TOTAL_COUNT), 2) AS WRONG_PRECENT " ..
        " FROM  T_ANALYSE_STUDY_STATE " ..
        " WHERE SUBJECT_ID=" .. subjectId .. conditionSegment .. " GROUP BY KNOWLEDGE_POINT_ID ) AS T2 " ..
        " ON T1.KNOWLEDGE_POINT_ID = T2.KNOWLEDGE_POINT_ID";
    
    -- 查询总数的sql    
    local  countSql    = "SELECT COUNT(1) AS TOTAL_ROW FROM (" .. querySql .. ") AS TEMP";
    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> 按学生统计知识点的个人错误率和班级错误率分页记录总数的sql语句 ： [[[", querySql, "]]]");
    local  countResult = DBUtil: querySingleSql(countSql);
    if not countResult then
        return { success = false, info = "获取总数失败" };
    end
    
    local totalRow  = tonumber(countResult[1]["TOTAL_ROW"]);
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
    local offset    = pageSize*pageNumber-pageSize;
    local limit     = pageSize;
    
    querySql = "SELECT * FROM (" .. querySql .. ") AS TEMP " .. sortSegment .. " LIMIT " .. offset .. "," .. limit .. ";";
    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]->  按学生统计知识点的个人错误率和班级错误率的sql语句 ： [[[", querySql, "]]]");
    
    local  queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return { success = false, info = "获取数据失败" };
    end
    
    local pageResult  = {};
    
    local resultTable = {};
    for index=1, #queryResult do
        local record     = queryResult[index];
        local tempRecord = {};
        
        tempRecord["knowledge_point_id"]   = record["KNOWLEDGE_POINT_ID"];
        tempRecord["knowledge_point_name"] = record["KNOWLEDGE_POINT_NAME"];
        tempRecord["self_wrong_precent"]   = record["SELF_WRONG_PRECENT"];
        tempRecord["class_wrong_precent"]  = record["WRONG_PRECENT"];
        
        table.insert(resultTable, tempRecord);
    end
    
    pageResult.success        = true;
    pageResult.totalRow       = totalRow;
    pageResult.totalPage      = totalPage;
    pageResult.pageNumber     = pageNumber;
    pageResult.pageSize       = pageSize;
    pageResult.analyse_result = resultTable;
    
    return pageResult;

end

_AnalyseData.analyseWrongPreByStudent = analyseWrongPreByStudent;

-- ----------------------------------------------------------------------------------------------
--[[
    描述： 获取错误的知识点(按错误率倒序排列，支持分页)
    参数： subjectId       科目ID
    参数： classId         班级ID
    参数： startTime       开始时间
    参数： endTime         结束时间
    参数： queryKey        关键字，知识点名称
    参数： pageNumber      当前页数
    参数： pageSize        每页显示记录条数
    返回值：    table对象，存储查询结果和分页信息
]]
local function getWrongKnowPoint(self, subjectId, teacherId, classId, startTime, endTime, queryKey, pageNumber, pageSize)
    
    local DBUtil = require "common.DBUtil";

    -- sql 的条件片段
    local segmentWhere = " FROM T_ANALYSE_STUDY_STATE WHERE SUBJECT_ID=" .. subjectId ;

    local segmentClass = self: getSqlClassSegment(classId, subjectId, teacherId);
    if segmentClass ~= "" then
        segmentWhere = segmentWhere .. " AND " .. segmentClass;
    end

    if startTime ~= nil and startTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME > '" .. startTime .. "'";
    end
    
    if endTime ~= nil and endTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME < '" .. endTime .. "'";
    end

    if queryKey ~= nil and queryKey ~= "" then
        segmentWhere = segmentWhere .. " AND KNOWLEDGE_POINT_NAME LIKE '%" .. queryKey .. "%'";
    end

    local  countSql    = "SELECT COUNT(DISTINCT KNOWLEDGE_POINT_ID) AS TOTAL_ROW FROM (SELECT KNOWLEDGE_POINT_ID " .. segmentWhere .. ") AS TEMP;";
    local  countResult = DBUtil: querySingleSql(countSql);
    if not countResult then
        return { success = false, info = "获取总数失败" };
    end
    
    local totalRow  = tonumber(countResult[1]["TOTAL_ROW"]);
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
    local offset    = pageSize*pageNumber-pageSize;
    local limit     = pageSize;

    local querySql  = "SELECT * FROM (SELECT KNOWLEDGE_POINT_ID, KNOWLEDGE_POINT_NAME, TRUNCATE(SUM(WRONG_COUNT)/SUM(TOTAL_COUNT), 2) AS WRONG_PRECENT " .. segmentWhere .. "  GROUP BY KNOWLEDGE_POINT_ID) AS TEMP ORDER BY WRONG_PRECENT DESC LIMIT " .. offset .. "," .. limit .. ";";
    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> 教师获取错误知识点列表（带分页）的sql语句 ： [[[", querySql, "]]]");
    
    local  queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return { success = false, info = "获取数据失败" };
    end
    
    local pageResult  = {};
    local resultTable = {};
    for index=1, #queryResult do
        local record     = queryResult[index];
        local tempRecord = {};
        
        tempRecord["knowledge_point_id"]   = record["KNOWLEDGE_POINT_ID"];
        tempRecord["knowledge_point_name"] = record["KNOWLEDGE_POINT_NAME"];
        tempRecord["wrong_precent"]        = record["WRONG_PRECENT"];
        
        table.insert(resultTable, tempRecord);
    end
    
    pageResult.success              = true;
    pageResult.totalRow             = totalRow;
    pageResult.totalPage            = totalPage;
    pageResult.pageNumber           = pageNumber;
    pageResult.pageSize             = pageSize;
    pageResult.knowledge_point_list = resultTable;
    
    return pageResult;
end

_AnalyseData.getWrongKnowPoint = getWrongKnowPoint;

-- ----------------------------------------------------------------------------------------------
--[[
    描述： 按知识点统计错误率
    参数： subjectId       科目ID
    参数： teacherId       教师ID
    参数： classId         班级ID
    参数： querykey        知识点名称，用于模糊查询
    参数： startTime       开始时间
    参数： endTime         结束时间
    参数： pageNumber      当前页数
    参数： pageSize        每页显示的条数
    参数： sortField       排序字段
    参数： sortType        排序类型：1升序，2降序
    返回值：    table对象，存储查询结果和分页信息
]]
local function analyseByKnowledge(self, subjectId, teacherId, classId, querykey, startTime, endTime, pageNumber, pageSize, sortField, sortType)
    
    local sql = "SELECT KNOWLEDGE_POINT_ID, KNOWLEDGE_POINT_NAME, SUM(TOTAL_COUNT) AS TOTAL_SUM, " ..
    "SUM(WRONG_COUNT) AS WRONG_SUM, TRUNCATE(WRONG_SUM/TOTAL_SUM, 2) AS WRONG_PRECENT " ..
    "FROM T_ANALYSE_STUDY_STATE WHERE SUBJECT_ID=[***] AND CLASS_ID IN () AND SEX_ID IN () " ..
    "AND CREATE_TIME > [] AND CREATE_TIME < [] GROUP BY KNOWLEDGE_POINT_ID;";
    
end

_AnalyseData.analyseByKnowledge = analyseByKnowledge;

-- ----------------------------------------------------------------------------------------------
--[[
    描述： 统计单个知识点下学生的错误率
    参数： knowledgeId     知识点ID
    参数： teacherId       教师ID
    参数： classId         班级ID
    参数： sexId           性别ID
    参数： querykey        知识点名称，用于模糊查询
    参数： startTime       开始时间
    参数： endTime         结束时间
    参数： pageNumber      当前页数
    参数： pageSize        每页显示的条数
    参数： sortField       排序字段
    参数： sortType        排序类型：1升序，2降序
    返回值：    table对象，存储查询结果和分页信息
]]
local function analyseByKnowledgeAndStu(self, subjectId, knowledgeId, teacherId, classId, sexId, querykey, startTime, endTime, pageNumber, pageSize, sortField, sortType)
    local DBUtil = require "common.DBUtil";
    local segmentWhere = " FROM T_ANALYSE_STUDY_STATE WHERE KNOWLEDGE_POINT_ID=" .. knowledgeId ;
    
    -- sql 的条件片段
    local segmentClass = self: getSqlClassSegment(classId, subjectId, teacherId);
    if segmentClass ~= "" then
        segmentWhere = segmentWhere .. " AND " .. segmentClass;
    end

    if sexId ~= nil and sexId ~= "" then
        segmentWhere = segmentWhere .. " AND SEX_ID = '" .. sexId .. "'";
    end

    if startTime ~= nil and startTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME > '" .. startTime .. "'";
    end
    
    if endTime ~= nil and endTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME < '" .. endTime .. "'";
    end


    local  countSql    = "SELECT COUNT(DISTINCT STUDENT_ID) AS TOTAL_ROW " .. segmentWhere;
    local  countResult = DBUtil: querySingleSql(countSql);
    if not countResult then
        return { success = false, info = "获取总数失败" };
    end
    
    local totalRow  = tonumber(countResult[1]["TOTAL_ROW"]);
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
    local offset    = pageSize*pageNumber-pageSize;
    local limit     = pageSize;

    local querySql  = "SELECT STUDENT_ID, STUDENT_NAME, SUM(TOTAL_COUNT) AS TOTAL_COUNT, SUM(WRONG_COUNT) AS WRONG_COUNT, SUM(RIGHT_COUNT) AS RIGHT_COUNT, TRUNCATE(SUM(WRONG_COUNT)/SUM(TOTAL_COUNT), 2) AS WRONG_PRECENT " .. segmentWhere .. " GROUP BY STUDENT_ID ";
    if sortField ~= nil and sortField ~= "" and sortType ~= nil and sortType ~= "" then
        local sortFieldTable = { 
            total_count   = "TOTAL_COUNT", 
            wrong_count   = "WRONG_COUNT", 
            right_count   = "RIGHT_COUNT",
            wrong_precent = "WRONG_PRECENT"
        };
        querySql = querySql .. " ORDER BY " .. sortFieldTable[sortField] .. " " .. ((sortType==1 and "ASC") or "DESC");
    else
        querySql = querySql .. " ORDER BY WRONG_PRECENT DESC";
    end

    querySql = querySql .. " LIMIT " .. offset .. "," .. limit .. ";";
    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> 按知识点和学生统计错题率（带分页）的sql语句 ： [[[", querySql, "]]]");
    
    local  queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return { success = false, info = "获取数据失败" };
    end
    
    local pageResult  = {};
    
    local resultTable = {};
    for index=1, #queryResult do
        local record     = queryResult[index];
        local tempRecord = {};
        
        tempRecord["student_id"]    = record["STUDENT_ID"];
        tempRecord["studetn_name"]  = record["STUDENT_NAME"];
        tempRecord["wrong_count"]   = record["WRONG_COUNT"];
        tempRecord["right_count"]   = record["RIGHT_COUNT"];
        tempRecord["total_count"]   = record["TOTAL_COUNT"];
        tempRecord["wrong_precent"] = record["WRONG_PRECENT"];
        
        table.insert(resultTable, tempRecord);
    end
    
    pageResult.success              = true;
    pageResult.totalRow             = totalRow;
    pageResult.totalPage            = totalPage;
    pageResult.pageNumber           = pageNumber;
    pageResult.pageSize             = pageSize;
    pageResult.knowledge_point_list = resultTable;
    
    return pageResult;
end

_AnalyseData.analyseByKnowledgeAndStu = analyseByKnowledgeAndStu;
-- ----------------------------------------------------------------------------------------------

--[[
    描述：  按学生统计知识点的个人错误率和班级错误率
    参数：  subjectId       科目ID
    参数：  teacherId       教师ID
    参数：  classId         班级ID
    参数：  startTime       开始时间
    参数：  endTime         结束时间
    返回值：table对象，存储查询结果和分页信息
]]
local function analyseBySex(self, subjectId, knowledgeId, teacherId, classId, startTime, endTime)
    
    local DBUtil       = require "common.DBUtil";
    local segmentWhere = "";
    local segmentClass = "";
    
    -- sql 的条件片段
    local segmentClass = self: getSqlClassSegment(classId, subjectId, teacherId);
    if segmentClass ~= "" then
        segmentWhere = segmentWhere .. segmentClass;
    end

    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> segmentClass -> [[[" , segmentClass, "]]");
    if startTime ~= nil and startTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME > '" .. startTime .. "'";
    end
    
    if endTime ~= nil and endTime ~= "" then
        segmentWhere = segmentWhere .. " AND CREATE_TIME < '" .. endTime .. "'";
    end 

    local querySql = "SELECT CLASS.CLASS_ID, CLASS.CLASS_NAME, " .. 
                "IFNULL(BOY_TOTAL_SUM, 0) AS BOY_TOTAL_SUM, IFNULL(BOY_WRONG_SUM, 0) AS BOY_WRONG_SUM,  " ..
                "IF((BOY_WRONG_SUM IS NULL OR BOY_WRONG_SUM=0), 0, TRUNCATE(BOY_WRONG_SUM/BOY_TOTAL_SUM, 2))  AS  BOY_WRONG_PRECENT, " ..
                "IFNULL(GIRL_TOTAL_SUM, 0) AS GIRL_TOTAL_SUM, IFNULL(GIRL_WRONG_SUM, 0) AS GIRL_WRONG_SUM, " .. 
                "IF((GIRL_WRONG_SUM IS NULL OR GIRL_WRONG_SUM=0), 0, TRUNCATE(GIRL_WRONG_SUM/GIRL_TOTAL_SUM, 2))  AS GIRL_WRONG_PRECENT " .. 
                "FROM T_BASE_CLASS CLASS " ..
                "LEFT OUTER JOIN ( " ..
                    "SELECT CLASS_ID,  " ..
                    "SUM(IF(SEX_ID=1, TOTAL_COUNT, 0)) AS BOY_TOTAL_SUM, " ..
                    "SUM(IF(SEX_ID=1, WRONG_COUNT, 0)) AS BOY_WRONG_SUM, " ..
                    "SUM(IF(SEX_ID=2, TOTAL_COUNT, 0)) AS GIRL_TOTAL_SUM, " ..
                    "SUM(IF(SEX_ID=2, WRONG_COUNT, 0)) AS GIRL_WRONG_SUM " ..
                    "FROM T_ANALYSE_STUDY_STATE WHERE KNOWLEDGE_POINT_ID=" .. knowledgeId ..
                    " AND ".. segmentWhere ..   
                    " GROUP BY CLASS_ID " ..
                ") AS ANALYSE_TAB " ..
                "ON CLASS.CLASS_ID = ANALYSE_TAB.CLASS_ID   " ..
                "WHERE CLASS." .. segmentClass;
    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> 按性别进行统计错题率（带分页）的sql语句 ： [[[", querySql, "]]]");
    
    local  queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return { success = false, info = "获取数据失败" };
    end    
    
    local resultTable = {};
    for index=1, #queryResult do
        local record     = queryResult[index];
        local tempRecord = {};
        
        tempRecord["class_id"]           = record["CLASS_ID"];
        tempRecord["class_name"]         = record["CLASS_NAME"];
        tempRecord["boy_total_sum"]      = record["BOY_TOTAL_SUM"];
        tempRecord["boy_wrong_sum"]      = record["BOY_WRONG_SUM"];
        tempRecord["boy_wrong_precent"]  = record["BOY_WRONG_PRECENT"];
        tempRecord["girl_total_sum"]     = record["GIRL_TOTAL_SUM"];
        tempRecord["girl_wrong_sum"]     = record["GIRL_WRONG_SUM"];
        tempRecord["girl_wrong_precent"] = record["GIRL_WRONG_PRECENT"];
        
        table.insert(resultTable, tempRecord);
    end

    return resultTable;
end

_AnalyseData.analyseBySex = analyseBySex;
-- ----------------------------------------------------------------------------------------------
--[[
    描述：  获取sql语句的班级条件片段，如果classId有值，则只查询指定的班级，
            如果classId没有值，则查询该教师在指定科目下任教的所有班级
    参数：  classId         班级ID
    参数：  subjectId       科目ID
    参数：  teacherId       教师ID
    返回值：班级部分的sql语句片段
]]
local function getSqlClassSegment(self, classId, subjectId, teacherId)

    local sqlSegmentClass = "";

    if classId ~= nil and classId ~= "" and classId ~= 0 then
        sqlSegmentClass = "CLASS_ID=" .. classId .. "";
    else
        local personService = require "base.person.services.PersonService";
        local classResult   = personService: getTeachClassesBySubject(teacherId, subjectId);
        if classResult.success then
            local classList    = classResult.class_list;
            if #classList > 0 then
                sqlSegmentClass =  sqlSegmentClass .. "CLASS_ID IN ( ";
                for index = 1, #classList do
                    if index == 1 then 
                        sqlSegmentClass  =  sqlSegmentClass .. classList[index]["class_id"];
                    else
                        sqlSegmentClass  =  sqlSegmentClass .. "," .. classList[index]["class_id"];
                    end
                end
                sqlSegmentClass = sqlSegmentClass .. " )";
            end
        end
    end

    return sqlSegmentClass;
end

_AnalyseData.getSqlClassSegment = getSqlClassSegment;
-- ----------------------------------------------------------------------------------------------
return _AnalyseData;