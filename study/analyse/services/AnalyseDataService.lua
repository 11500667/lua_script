--
-- 学情分析的业务函数
-- User: 申健
-- Date: 2015/5/5
-- Time: 8:26
--

local _AnalyseDataService = {}

-- ----------------------------------------------------------------------------------------------
--[[
    描述：  插入学情分析的统计数据
    参数：  subjectId       科目ID
    参数：  classId         班级ID
    参数：  studentId       学生ID
    参数：  questionIdChar  试题的GUID    
    参数：  rightFlag       正确标识：0错误，1正确
    返回值：table对象，存储查询结果和分页信息
]]
local function insertAnalyseData(self, subjectId, classId, studentId, questionIdChar, rightFlag)
    
    local studentModel = require "base.student.model.Student";
    local studentInfo = studentModel: getById(studentId);
    
    if not studentInfo then
        ngx.log(ngx.ERR, "===> 保存学情分析统计数据失败，失败原因--> 根据学生ID：[", studentId, "] 获取学生信息出错！");
        return false;
    end
    
    local sexId = 1; -- 性别：1为男，2为女
    if studentInfo["XB_NAME"] ~= nil or studentInfo["XB_NAME"] ~= ngx.null or studentInfo["XB_NAME"] ~= "" then 
         sexId = ((studentInfo["XB_NAME"] == "男" and 1) or 2);
    end
    
    local dataTable = {};
    dataTable.subject_id           = subjectId;
    dataTable.class_id             = classId;
    dataTable.student_id           = studentId;
    dataTable.student_name         = studentInfo["STUDENT_NAME"];
    dataTable.sex_id               = sexId;
    dataTable.total_count          = 1;
    dataTable.right_count          = (rightFlag == 0 and 0) or 1;
    dataTable.wrong_count          = (rightFlag == 0 and 1) or 0;
    
    local questionBase   = require "question.model.QuestionBase";
    local questionResult = questionBase: getQuesDetailByIdChar(questionIdChar);
    if not questionResult then
        ngx.log(ngx.ERR, "===> 保存学情分析统计数据失败，失败原因--> 根据试题INFO_ID：[", studentId, "] 获取试题信息出错！");
        return false;
    end
    
    dataTable.question_id_char = questionResult["question_id_char"]; 

    local kpList = questionResult["knowledge_point_list"];
    if kpList == nil or kpList == ngx.null or #kpList == 0 then
        -- ngx.log(ngx.ERR, "===> 保存学情分析统计数据失败，失败原因--> 根据试题INFO_ID：[", studentId, "] 没有获取到试题的知识点！");
        return false;
    end
    
    local analyseDataModel = require "study.analyse.model.AnalyseData";
    for index = 1, #kpList do
        local kp = kpList[index];
        dataTable.knowledge_point_id   = kp["structure_id_int"];
        dataTable.knowledge_point_name = kp["structure_name"];
        
        analyseDataModel: insertData(dataTable);
    end
    
    return true;
end

_AnalyseDataService.insertAnalyseData = insertAnalyseData;

-- ----------------------------------------------------------------------------------------------

return _AnalyseDataService;