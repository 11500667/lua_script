--
-- 学情分析的业务函数
-- User: 申健
-- Date: 2015/5/5
-- Time: 8:26
--

local _localServiceObj = {}

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
    
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local resultTable      = analyseDataModel: analyseByClass(subjectId, teacherId, classId, studentName, startTime, endTime, sortField, sortType);
    
    if not resultTable then
        return { success = false, info = "获取数据失败" };
    end
    return { success = true, analyse_result = resultTable};
end

_localServiceObj.analyseByClass = analyseByClass;

-- ----------------------------------------------------------------------------------------------

--[[
    描述：   按学生统计知识点的个人错误率和班级错误率
    参数： subjectId       科目ID
    参数： classId         班级ID
    参数： startTime       开始时间
    参数： endTime         结束时间
    参数： studentId       当前页数
    参数： pageNumber      当前页数
    参数： pageSize        每页显示的记录条数
    参数： sortField       排序字段
    参数： sortType        1升序，2降序
    返回值：    table对象，存储查询结果和分页信息
]]
local function analyseWrongPreByStudent(self, subjectId, classId, teacherId, studentId, startTime, endTime, pageNumber, pageSize, sortField, sortType)
    
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local pageResult = analyseDataModel: analyseWrongPreByStudent(subjectId, classId, teacherId, studentId, startTime, endTime, pageNumber, pageSize, sortField, sortType);
    
    return pageResult;
    
end

_localServiceObj.analyseWrongPreByStudent = analyseWrongPreByStudent;

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
    
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local analyseResult    = analyseDataModel: analyseBySex(subjectId, knowledgeId, teacherId, classId, startTime, endTime);
    if not analyseResult then
        return { success = false, info = "获取数据失败" };
    end

    return { success = true, analyse_result = analyseResult };
end

_localServiceObj.analyseBySex = analyseBySex;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   获取指定科目、班级下的错误知识点，并按照错题数进行排序
	参数：	 subjectId 	 	科目ID
	参数：	 classId 	 	班级ID
	参数：	 startTime 	 	开始时间
	参数：	 endTime 	 	结束时间
	参数：	 pageNumber 	当前页数
	参数：	 pageSize 	 	每页显示的记录条数
	返回值： table对象，存储查询结果和分页信息
]]
local function getKnowledgeByPageSort(self, subjectId, teacherId, classId, startTime, endTime, querykey, pageNumber, pageSize, sortField, sortType)

    local subQuerySql = "SELECT KNOWLEDGE_POINT_ID, KNOWLEDGE_POINT_NAME, SUM(TOTAL_COUNT) AS TOTAL_COUNT, SUM(WRONG_COUNT) AS WRONG_COUNT, SUM(RIGHT_COUNT) AS RIGHT_COUNT, TRUNCATE(SUM(WRONG_COUNT)/SUM(TOTAL_COUNT), 2) AS WRONG_PRECENT FROM t_analyse_study_state WHERE SUBJECT_ID=" .. subjectId;
    -- 是否指定班级，如果没有指定班级，则获取教师在该科目下教授的所有班级
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local segmentClass     = analyseDataModel: getSqlClassSegment(classId, subjectId, teacherId);
    if segmentClass ~= "" then
        subQuerySql = subQuerySql .. " AND " .. segmentClass;
    end

    if startTime ~= nil and startTime ~= "" then
        subQuerySql = subQuerySql .. " AND CREATE_TIME > '" .. startTime .. "'";
    end

    if endTime ~= nil and endTime ~= "" then
        subQuerySql = subQuerySql .. " AND CREATE_TIME < '" .. endTime .. "'";
    end

    if querykey ~= nil and querykey ~= "" then
        subQuerySql = subQuerySql .. " AND KNOWLEDGE_POINT_NAME LIKE '%" .. querykey .. "%'";
    end

    local countSql  = "SELECT COUNT(1) AS TOTAL_COUNT FROM (" .. subQuerySql .. " GROUP BY KNOWLEDGE_POINT_ID) AS COUNT_TABLE;";
    local DBUtil    = require "common.DBUtil";
    local resultObj = {};

    local countResult = DBUtil: querySingleSql(countSql);
    if not countResult then
        return false;
    end
    local totalRow  = countResult[1]["TOTAL_COUNT"];
    local totalPage = math.floor((totalRow + pageSize - 1) / pageSize);
    local offset    = pageSize * pageNumber - pageSize;
    local limit     = pageSize;

    local querySql = "SELECT * FROM (" .. subQuerySql .. " GROUP BY KNOWLEDGE_POINT_ID) AS SUB_QUERY ";
    if sortField ~= nil and sortField ~= "" and sortType ~= nil and sortType ~= "" then
        local sortFieldTable = { 
            total_count   = "TOTAL_COUNT", 
            wrong_count   = "WRONG_COUNT", 
            right_count   = "RIGHT_COUNT",
            wrong_precent = "WRONG_PRECENT"
        };
        querySql = querySql .. " ORDER BY " .. sortFieldTable[sortField] .. " " .. ((sortType==1 and "ASC") or "DESC");
    else
        querySql = querySql .. " ORDER BY SUB_QUERY.WRONG_COUNT DESC";
    end

    querySql = querySql .. " LIMIT " .. offset .. "," .. limit .. ";";

    ngx.log(ngx.ERR, "[sj_log]->[study_analyse]-> 按知识点进行统计（获取错误知识点）的sql语句-> [[[", querySql, "]]]");

    local queryResult = DBUtil:querySingleSql(querySql);
    if not queryResult then
        return false;
    end

    local zsdListObj = {};
    for i=1, #queryResult do
        local record = {};
        record["knowledge_point_id"]   = queryResult[i]["KNOWLEDGE_POINT_ID"];
        record["knowledge_point_name"] = queryResult[i]["KNOWLEDGE_POINT_NAME"];
        record["total_count"]          = queryResult[i]["TOTAL_COUNT"];
        record["wrong_count"]          = queryResult[i]["WRONG_COUNT"];
        record["right_count"]          = queryResult[i]["RIGHT_COUNT"];
        record["wrong_precent"]        = queryResult[i]["WRONG_PRECENT"];

        table.insert(zsdListObj, record);
    end

    resultObj["success"]        = true;
    resultObj["totalRow"]       = totalRow;
    resultObj["totalPage"]      = totalPage;
    resultObj["pageNumber"]     = pageNumber;
    resultObj["pageSize"]       = pageSize;
    resultObj["knowledge_list"] = zsdListObj;

    return resultObj;
end

_localServiceObj.getKnowledgeByPageSort = getKnowledgeByPageSort;

-- ----------------------------------------------------------------------------------------------
--[[
    描述：  按科目获取错误的知识点
    参数：  subjectId       科目ID
    参数：  startTime       开始时间
    参数：  endTime         结束时间
    返回值：table对象，存储查询结果和分页信息
]]
local function getWrongKnowPoint(self, subjectId, startTime, endTime, querykey, pageNumber, pageSize)
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local pageResult = analyseDataModel: getWrongKnowPoint(subjectId, startTime, endTime, querykey);
    
    return pageResult;
end

_localServiceObj.getWrongKnowPoint = getWrongKnowPoint;

-- ----------------------------------------------------------------------------------------------
--[[
    描述：  按知识点统计错误率
    参数：  subjectId       科目ID
    参数：  teacherId       教师ID
    参数：  classId         班级ID
    参数：  querykey        知识点名称，用于模糊查询
    参数：  startTime       开始时间
    参数：  endTime         结束时间
    参数：  pageNumber      当前页数
    参数：  pageSize        每页显示的条数
    参数：  sortField       排序字段
    参数：  sortType        排序类型：1升序，2降序
    返回值：table对象，存储查询结果和分页信息
]]
local function analyseByKnowledge(self, subjectId, teacherId, classId, querykey, startTime, endTime, pageNumber, pageSize, sortField, sortType)
    
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local pageResult = analyseDataModel: analyseByKnowledge(subjectId, teacherId, classId, querykey, startTime, endTime, pageNumber, pageSize, sortField, sortType);
    
    return pageResult;
end

_localServiceObj.analyseByKnowledge = analyseByKnowledge;
-- ----------------------------------------------------------------------------------------------
--[[
    描述： 按知识点、学生统计错误数、正确数、总数、错误率
    参数： knowledgeId     知识点ID
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
local function analyseByKnowAndStu(self, subjectId, knowledgeId, teacherId, classId, sexId, querykey, startTime, endTime, pageNumber, pageSize, sortField, sortType )
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    local pageResult = analyseDataModel: analyseByKnowledgeAndStu(subjectId, knowledgeId, teacherId, classId, sexId, querykey, startTime, endTime, pageNumber, pageSize, sortField, sortType);
    
    return pageResult;
end

_localServiceObj.analyseByKnowAndStu = analyseByKnowAndStu;
-- ----------------------------------------------------------------------------------------------

return _localServiceObj;