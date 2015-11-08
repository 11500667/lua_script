--
-- 学生点评 -> 点评信息的基础函数
-- 作者: shenjian
-- 日期: 2015/5/5 14:50
--

local _CommentInfo = {};

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   保存用户对指定对象的点评信息（新增）
	作者：   申健    2015-05-05
	参数：	paramTable 	 包含点评信息内容的参数对象
	返回值：	保存成功返回新评论信息的ID， 保存失败返回false
]]
local function createCommentInfo(self, paramTable)

    local objType     = paramTable["obj_type"];
    local objId       = paramTable["obj_id"];
    local personId    = paramTable["person_id"];
    local identityId  = paramTable["identity_id"];
    local classId     = paramTable["class_id"];
    local itemScore1  = paramTable["item_score1"];
    local itemScore2  = paramTable["item_score2"];
    local itemScore3  = paramTable["item_score3"];
    local itemScore4  = paramTable["item_score4"];
    local commentText = paramTable["comment_text"];

    local insertSql = "INSERT INTO T_STUDY_COMMENT_INFO (PERSON_ID, IDENTITY_ID, CLASS_ID, OBJ_TYPE, OBJ_ID, ITEM_SCORE1, ITEM_SCORE2, ITEM_SCORE3, ITEM_SCORE4, COMMENT_TEXT, CREATE_TIME) VALUES (" .. personId .. ", " .. identityId .. ", " .. classId .. ", " .. objType .. ", " .. objId .. ", " .. itemScore1 .. ", " .. itemScore2 .. ", " .. itemScore3 .. ", " .. itemScore4 .. ", " .. ngx.quote_sql_str(commentText) .. ", NOW() ) ;";

    local DBUtil       = require "common.DBUtil";
    local insertResult = DBUtil: querySingleSql(insertSql);
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "===> 保存点评信息的sql语句：[[[", insertSql, "]]] <===> 保存点评信息, 执行sql语句的返回结果：[[[", cjson.encode(insertResult), "]]] <=== ");
    if not insertResult then
        return false;
    end
    -- 插入语句的返回值：类型table，格式：{"insert_id":770862,"server_status":11,"warning_count":0,"affected_rows":1}
    --return insertResult["insert_id"];
    return true;
end

_CommentInfo.createCommentInfo = createCommentInfo;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   更新指定用户对指定对象的点评信息
	作者：   申健    2015-05-05
	参数：	paramTable 	 包含点评信息内容的参数对象
	返回值：	保存成功返回新评论信息的ID， 保存失败返回false
]]
local function updateCommentInfo(self, paramTable)

    local recordId    = paramTable["record_id"];
    local itemScore1  = paramTable["item_score1"];
    local itemScore2  = paramTable["item_score2"];
    local itemScore3  = paramTable["item_score3"];
    local itemScore4  = paramTable["item_score4"];
    local commentText = paramTable["comment_text"];

    local updateSql = "UPDATE T_STUDY_COMMENT_INFO SET ITEM_SCORE1 = " .. itemScore1 .. ", ITEM_SCORE2 = " .. itemScore2 .. ", ITEM_SCORE3 = " .. itemScore3 .. ", ITEM_SCORE4 = " .. itemScore4 .. ", COMMENT_TEXT = " .. ngx.quote_sql_str(commentText) .. ", CREATE_TIME = NOW() WHERE ID = " .. recordId .. " ;";

    local  DBUtil       = require "common.DBUtil";
    local  updateResult = DBUtil: querySingleSql(updateSql);
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "===> 更新点评信息的sql语句：[[[", updateSql, "]]] <===> 更新点评信息, 执行sql语句的返回结果：[[[", cjson.encode(updateResult), "]]] <=== ");
    if not updateResult then
        return false;
    end


    -- 插入语句的返回值：类型table，格式：{"insert_id":770862,"server_status":11,"warning_count":0,"affected_rows":1}
    return true;
end

_CommentInfo.updateCommentInfo = updateCommentInfo;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   判断指定用户针对指定对象（话题、作业）是否已经进行过评论
	作者：   申健    2015-05-05
	参数：	objType 	 对象类型：1话题，2作业
	参数：	objId 	 	 对象的ID
	参数：	personId 	 评论人员的ID
	参数：	identityId 	 评论人员的身份ID
	返回值：	已经评论过返回评论信息的ID， false表示没有评论过， nil表示出错
]]
local function isCommentInfoExist(self, objType, objId, personId, identityId)

    local querySql = "SELECT ID FROM T_STUDY_COMMENT_INFO WHERE OBJ_TYPE=" .. objType .. " AND OBJ_ID=" .. objId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " LIMIT 1;";
    ngx.log(ngx.ERR, "===> 判断用户是否已经评论过的该对象的SQL语句：[[[", querySql, "]]]");

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return nil;
    end

    if #queryResult == 0 then
        return false;
    end
    local recordId = queryResult[1]["ID"];
    return recordId;
end

_CommentInfo.isCommentInfoExist = isCommentInfoExist;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   获取指定用户对指定对象的点评信息
	作者：   申健    2015-05-05
	参数：	objType 	 对象类型：1话题，2作业
	参数：	objId 	 	 对象的ID
	参数：	personId 	 评论人员的ID
	参数：	identityId 	 评论人员的身份ID
	返回值：	返回的点评信息的对象，如果对象不存在，则返回默认的对象（所有评分都为0），查询出错返回false
]]
local function getCommentInfo(self, objType, objId, personId, identityId)

    local querySql = "SELECT ID, ITEM_SCORE1, ITEM_SCORE2, ITEM_SCORE3, ITEM_SCORE4, COMMENT_TEXT FROM T_STUDY_COMMENT_INFO WHERE OBJ_TYPE=" .. objType .. " AND OBJ_ID=" .. objId .. " AND PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .. " LIMIT 1;";
    ngx.log(ngx.ERR, "===> 获取点评信息的的SQL语句：[[[", querySql, "]]]");

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return false;
    end

    if #queryResult == 0 then
        return { item_score1=0, item_score2=0, item_score3=0, item_score4=0, comment_text="" };
    end

    local record = {};
    record.item_score1  = queryResult[1]["ITEM_SCORE1"];
    record.item_score2  = queryResult[1]["ITEM_SCORE2"];
    record.item_score3  = queryResult[1]["ITEM_SCORE3"];
    record.item_score4  = queryResult[1]["ITEM_SCORE4"];
    record.comment_text = queryResult[1]["COMMENT_TEXT"];
    return record;

end

_CommentInfo.getCommentInfo = getCommentInfo;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   获取所学生对指定对象的平均点评分数
	作者：   申健        2015-05-05
	参数：	 objType 	 对象类型：1话题，2作业
	参数：	 objId 	 	 对象的ID
	返回值:  返回的平均点评信息的对象，如果对象不存在，则返回默认的对象（所有评分都为0），查询出错返回false
]]
local function getAverageCommentInfo(self, objType, objId, classId)

    local querySql = "SELECT TRUNCATE(AVG(ITEM_SCORE1),1) AS ITEM_SCORE1, TRUNCATE(AVG(ITEM_SCORE2),1) AS ITEM_SCORE2, TRUNCATE(AVG(ITEM_SCORE3),1) AS ITEM_SCORE3, TRUNCATE(AVG(ITEM_SCORE4), 1) AS ITEM_SCORE4 FROM T_STUDY_COMMENT_INFO WHERE OBJ_ID=" .. objId .. " AND OBJ_TYPE=" .. objType .. " AND CLASS_ID=" .. classId .. " GROUP BY OBJ_ID";
    ngx.log(ngx.ERR, "===> 获取平均点评信息的的SQL语句：[[[", querySql, "]]]");

    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil: querySingleSql(querySql);
    if not queryResult then
        return false;
    end

    if #queryResult == 0 then
        return { item_score1=0, item_score2=0, item_score3=0, item_score4=0 };
    end

    local record = {};
    record.item_score1  = queryResult[1]["ITEM_SCORE1"];
    record.item_score2  = queryResult[1]["ITEM_SCORE2"];
    record.item_score3  = queryResult[1]["ITEM_SCORE3"];
    record.item_score4  = queryResult[1]["ITEM_SCORE4"];
    return record;
end

_CommentInfo.getAverageCommentInfo = getAverageCommentInfo;
-- ----------------------------------------------------------------------------------------------

return _CommentInfo;