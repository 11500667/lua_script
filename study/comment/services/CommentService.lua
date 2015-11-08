--
-- 学生点评 话题的服务函数
-- User: shenjian
-- Date: 2015/5/5
-- Time: 13:16
--
local _CommentService = {}

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

    local  topicModel = require "study.comment.model.Topic";
    local  topicId    = topicModel: createTopic(topicName, teacherId);
    if not topicId then
        return { success = false, info = "创建话题失败"};
    end

    return { success = true, info = "保存话题成功", topic_id = topicId };
end

_CommentService.createTopic = createTopic;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   获取指定教师 在 指定班级 下创建的话题列表
	作者：   申健    2015-05-05
	参数：	teacherId 	 	教师ID
	参数：	classId 	 	班级ID
	返回值：	存储查询结果的table对象
]]
local function getTopicListNoPage(self, teacherId, classId)

    local  topicModel = require "study.comment.model.Topic";
    local  topicTable    = topicModel: getTopicListNoPage(teacherId, classId);
    if not topicTable then
        return { success = false, info = "获取数据失败"};
    end

    return { success = true, topic_list = topicTable };
end

_CommentService.getTopicListNoPage = getTopicListNoPage;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   保存指定用户（教师、学生）对指定对象的点评记录，如果点评记录已经存在，则更新，如果不存在，则新增；
	作者：   申健    2015-05-05
	参数：	paramTable 	 	包含点评信息内容的参数对象
	返回值：	true保存成功，false保存失败
]]
local function saveCommentInfo(self, paramTable)

    local objType     = paramTable["obj_type"];
    local objId       = paramTable["obj_id"];
    local personId    = paramTable["person_id"];
    local identityId  = paramTable["identity_id"];

    local commentInfoModel = require "study.comment.model.CommentInfo";
    local recordId = commentInfoModel: isCommentInfoExist(objType, objId, personId, identityId);

    local result;
    if not recordId then -- 如果记录不存在，则新增
        result = commentInfoModel: createCommentInfo(paramTable);
    else -- 如果记录已经存在，则更新之前的记录
        paramTable["record_id"] = recordId;
        result = commentInfoModel: updateCommentInfo(paramTable);
    end

    if not result then
        return { success = false, info = "保存失败"};
    end

    return { success = true, info = "操作成功"};
end

_CommentService.saveCommentInfo = saveCommentInfo;

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

    local commentInfoModel = require "study.comment.model.CommentInfo";
    local record = commentInfoModel: getCommentInfo(objType, objId, personId, identityId);

    if not record then
        return { success = false, info = "获取数据失败"};
    end

    local resultTable = {};
    resultTable.success = true;
    resultTable.comment_info = record;

    return resultTable;
end

_CommentService.getCommentInfo = getCommentInfo;

-- ----------------------------------------------------------------------------------------------
--[[
	描述：   获取指定对象的学生的平均点评分数
	作者：   申健    2015-05-05
	参数：	objType 	 对象类型：1话题，2作业
	参数：	objId 	 	 对象的ID
	参数：	classId 	 班级的ID
	返回值：	返回存储平均分数的对象，如果对象不存在，则返回默认的对象（所有评分都为0），查询出错返回false
]]
local function getAverageCommentInfo(self, objType, objId, classId)

    local commentInfoModel = require "study.comment.model.CommentInfo";
    local record = commentInfoModel: getAverageCommentInfo(objType, objId, classId);

    if not record then
        return { success = false, info = "获取数据失败"};
    end

    local resultTable = {};
    resultTable.success = true;
    resultTable.comment_info = record;
    return resultTable;

end

_CommentService.getAverageCommentInfo = getAverageCommentInfo;
-- ----------------------------------------------------------------------------------------------

return _CommentService;