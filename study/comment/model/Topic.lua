--
-- 学生点评 话题的基础函数
-- User: shenjian
-- Date: 2015/5/5
-- Time: 13:16
--
local _Topic = {}

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   创建学习话题（用于点评）
	作者：   申健    2015-05-05
	参数：	topicName 	 	话题名称
	参数：	teacherId 	 	教师ID
	参数：	classId 	 	班级ID
	返回值：	保存成功返回新话题的ID， 保存失败返回false
]]
local function createTopic(self, topicName, teacherId)

    local insertSql    = "INSERT INTO T_STUDY_COMMENT (TOPIC_NAME, TEACHER_ID, CREATE_TIME) VALUES (" .. ngx.quote_sql_str(topicName) .. "," .. teacherId .. ", NOW());";
    ngx.log(ngx.ERR, "===> 创建学习话题的SQL语句：[[[", insertSql, "]]]");

    local DBUtil       = require "common.DBUtil";
    local insertResult = DBUtil: querySingleSql(insertSql);
    if not insertResult then
        return false;
    end
    -- 插入语句的返回值：类型table，格式：{"insert_id":770862,"server_status":11,"warning_count":0,"affected_rows":1}
    local topicId = insertResult["insert_id"];

    return topicId;
end

_Topic.createTopic = createTopic;


-- ----------------------------------------------------------------------------------------------
--[[
	描述：   查询教师创建的话题
	作者：   申健    2015-05-05
	参数：	teacherId 	 	教师ID
	参数：	classId 	 	班级ID
	返回值：	保存成功返回新话题的ID， 保存失败返回false
]]
local function getTopicListNoPage(self, teacherId, classId)

    local querySql = "SELECT T1.ID, T1.TOPIC_NAME, SUM(ITEM_SCORE1) AS TEMP_SCORE FROM T_STUDY_COMMENT T1 LEFT OUTER JOIN T_STUDY_COMMENT_INFO T2 ON T1.ID=T2.OBJ_ID AND T2.OBJ_TYPE=1 WHERE TEACHER_ID=" .. teacherId .. " AND CLASS_ID=" .. classId .. " GROUP BY T1.ID HAVING TEMP_SCORE > 0;";
    ngx.log(ngx.ERR, "===> [[查询学习话题]]的SQL语句：[[[", querySql, "]]]");

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return false;
    end

    local topicTable = {};
    for index = 1, #queryResult do
        local record = queryResult[index];

        local topic  = {};
        topic["topic_id"]   = record["ID"];
        topic["topic_name"] = record["TOPIC_NAME"];

        table.insert(topicTable, topic);
    end

    return topicTable;
end

_Topic.getTopicListNoPage = getTopicListNoPage;

-- ----------------------------------------------------------------------------------------------

return _Topic;