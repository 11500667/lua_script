--
--    张海  2015-05-06
--    描述：  BBS BbsPostService 接口.
--
local util = require("social.common.util")
local DBUtil = require "common.DBUtil";
local SsdbUtil = require("social.common.ssdbutil")
local TableUtil = require("social.common.table")
local TS = require "resty.TS"
local cjson = require "cjson"
local date = require("social.common.date")
local log = require("social.common.log")
local BbsPostService = {
}
local db = {

}
--------------------------------------------------------------------------------
local function splitAddSql(fields, values, tableName)

    local templet = "INSERT INTO `%s` (`%s`) VALUES (%s)"
    local query = templet:format(tableName, table.concat(fields, "`,`"), table.concat(values, ","))
    return query;
end

local function addTable(t, fieldStr, columns, values)
    table.insert(columns, fieldStr)
    table.insert(values, t[fieldStr])
end

--------------------------------------------------------------------------------
-- CREATE TABLE `t_social_bbs_post` (
-- `id` INT(11) NOT NULL COMMENT '主键',
-- `bbs_id` INT(11) NOT NULL COMMENT '论坛id',
-- `forum_id` INT(11) NOT NULL COMMENT '版块id',
-- `top_id` INT(11) NOT NULL COMMENT '主题帖id',
-- `title` VARCHAR(100) NULL DEFAULT NULL COMMENT '帖子标题',
-- `content` BLOB NULL COMMENT '帖子内容，引用回复时截取内容存在一起',
-- `person_id` INT(11) NULL DEFAULT NULL COMMENT '发帖人id',
-- `identity_id` INT(11) NULL DEFAULT NULL COMMENT '发帖人身份id',
-- `person_name` VARCHAR(32) NULL DEFAULT NULL COMMENT '真实姓名',
-- `create_time` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
-- `floor` INT(11) NULL DEFAULT NULL COMMENT '楼层,主帖算1楼',
-- `support_count` INT(10) NULL DEFAULT NULL COMMENT '支持数',
-- `oppose_count` INT(10) NULL DEFAULT NULL COMMENT '反对数',
-- `parent_id` INT(11) NOT NULL COMMENT '回复帖子id 回复哪个帖子',
-- `ancestor_id` INT(10) NOT NULL COMMENT '祖先帖子id',
-- PRIMARY KEY (`id`)
-- )
-- COMMENT='回帖表'
-- COLLATE='utf8_general_ci'
local function convertPost(post)
    local create_ts = TS.getTs()
    local t = {
        ID = post.id,
        BBS_ID = post.bbsId,
        FORUM_ID = post.forumId,
        TOPIC_ID = post.topicId,
        TITLE = ngx.quote_sql_str(post.title),
        CONTENT = ngx.quote_sql_str(post.content),
        PERSON_ID = post.personId,
        PERSON_NAME = ngx.quote_sql_str(post.personName),
        CREATE_TIME = "now()",
        FLOOR = post.floor,
        SUPPORT_COUNT = post.supportCount,
        OPPOSE_COUNT = post.opposeCount,
        IDENTITY_ID = post.identityId,
        PARENT_ID = post.parentId,
        ANCESTOR_ID = post.ancestorId,
        TS = create_ts,
        UPDATE_TS = create_ts,
        B_DELETE = post.bDelete,
        MESSAGE_TYPE = post.messageType
    }
    log.debug("保存回帖信息数据Table:");
    log.debug(t)
    return t;
end

--------------------------------------------------------------------------------
-- 保存回帖信息
-- @param #table post
-- @return #result 影响行数
function BbsPostService:savePost(post)
    if post == nil or TableUtil:length(post) == 0 then
        error("post is null");
    end
    post.bDelete = 0;
    local tempPost = convertPost(post)
    local column = {}
    local fileds = {}
    for key, var in pairs(tempPost) do
        if tempPost[key] then
            addTable(tempPost, key, column, fileds)
        end
    end
    local sql = splitAddSql(column, fileds, "T_SOCIAL_BBS_POST")
    log.debug("保存回帖信息sql:" .. sql);
    local result = DBUtil:querySingleSql(sql);
    log.debug(result)
    --topicid,lastPostId,replyerPersonId,replyerIdentityId
    --    local topicid = post.topicId;
    --    local lastPostId = post.id;
    --    local replyerPersonId = post.personId
    --    local replyerIdentityId = post.identityId
    --    local replyerPersonName = post.personName
    --    local BbsTopicService = require("social.service.BbsTopicService")
    --    BbsTopicService:updateTopicToDb(topicid, lastPostId, replyerPersonId, replyerIdentityId, replyerPersonName) --更新主题表的回复信息到数据库.

    return result
end

--------------------------------------------------------------------------------
-- 获取主键
function BbsPostService:getPostPkId()
    local db = SsdbUtil:getDb();
    local postid = db:incr("social_bbs_post_pk")[1] --生成主键id.
    util:logkeys("social_bbs_post_pk", "")
    return postid
end

function BbsPostService:getPostCount(topicid)
    local db = SsdbUtil:getDb();
    local partitionResult = db:hget("social_bbs_forum_topic_include_post", "topic_id_" .. topicid)
    util:log_r_keys("social_bbs_forum_topic_include_post", "hget")
    if partitionResult and string.len(partitionResult[1]) > 0 then
        local pidstr = partitionResult[1]
        local pids = Split(pidstr, ",")
        local count = #pids
        return count
    else
        return 0
    end
end
function BbsPostService:postCount(typeId)
    local db = SsdbUtil:getDb();
    local topic_typeid_key = "social_bbs_typeid_"..typeId
    local topicids =  db:get(topic_typeid_key);
    local count = 0
    if topicids and topicids[1] and string.len(topicids[1])>0 then
        count = self:getPostCount(topicids[1])
    end
    return count;
end

--------------------------------------------------------------------------------
--
-- 保存回帖信息(ssdb)
-- @param #table post
-- @return #result 影响行数
function BbsPostService:savePostToSsdb(post)
    if post == nil or TableUtil:length(post) == 0 then
        error("post is null");
    end
    if post.topicId == nil or string.len(post.topicId) == 0 then
        error("topic id is null");
    end
    post.createTime = date(os.date("%Y%m%d%H%M%S")):fmt("%Y-%m-%d %H:%M:%S")
    --local key = "social_bbs_topicid_" .. post.topicId .. "_postid_" .. post.id
    local key = "social_bbs_postid_" .. post.id
    post.bDelete = 0;
    local db = SsdbUtil:getDb();
    db:multi_hset(key, post)
    util:logkeys(key, "multi_hset")
    local postids_t, err = db:hget("social_bbs_forum_topic_include_post", "topic_id_" .. post.topicId)
    util:log_r_keys("social_bbs_forum_topic_include_post", "hget")
    local postids = ""
    if postids_t and string.len(postids_t[1]) > 0 then
        postids = postids_t[1] .. "," .. post.id
    else
        postids = post.id
    end
    db:hset("social_bbs_forum_topic_include_post", "topic_id_" .. post.topicId, postids)
    util:logkeys("social_bbs_forum_topic_include_post", "hset")
    --保存主题帖信息.
    --    local topicid = post.topicId;
    --    local lastPostId = post.id;
    --    local replyerPersonId = post.personId
    --    local replyerIdentityId = post.identityId
    --    local replyerPersonName = post.personName
    --    local BbsTopicService = require("social.service.BbsTopicService")
    --    BbsTopicService:updateTopicToSsdb(topicid, lastPostId, replyerPersonId, replyerIdentityId, replyerPersonName) --更新主题表的回复信息.
end

--------------------------------------------------------------------------------
local function getPostSphinxData(filter, pagenum, pagesize,sort)
    local offset = pagesize * pagenum - pagesize
    local limit = pagesize
    local str_maxmatches = "10000"
    local db = DBUtil:getDb();
    local sortf = sort and sort or "attr_asc:ts;"
    local sql = "SELECT SQL_NO_CACHE id FROM T_SOCIAL_BBS_POST_SPHINXSE WHERE query='%ssort=%smaxmatches=" .. str_maxmatches .. ";offset=" .. offset .. ";limit=" .. limit .. "';SHOW ENGINE SPHINX  STATUS;"
    sql = string.format(sql, filter,sortf);
    log.debug("sql :" .. sql)
    local res = db:query(sql)
    --去第二个结果集中的Status中截取总个数
    local res1 = db:read_result()
    --log.debug(res1)
    local _, s_str = string.find(res1[1]["Status"], "found: ")
    local e_str = string.find(res1[1]["Status"], ", time:")
    local totalRow = string.sub(res1[1]["Status"], s_str + 1, e_str - 1)
    local totalPage = math.floor((totalRow + pagesize - 1) / pagesize)
    return res, totalRow, totalPage
end



------------------------------------------------------------------------------
--- 通过personid获取头像地址。
--- @param #string personid
local function getIcon(personid, identityid)
    local info_key = "space_ajson_personbaseinfo_" .. personid .. "_" .. identityid;
    --log.debug("获取头像的 key：" .. info_key);
    local iconResult = SsdbUtil:getDb():get(info_key)
    local icon_url = "";
    if iconResult and iconResult[1] and string.len(iconResult[1]) > 0 then
       -- log.debug("获取头像的 value：" .. iconResult[1]);
        local jsonObj = cjson.decode(iconResult[1])
        icon_url = jsonObj.space_avatar_fileid
    end
    return icon_url;
end


--
--local function getPostById(postId)
--    local key = "social_bbs_postid_" .. postId
--    local keys = { "id", "content", "personId", "personName", "createTime", "floor", "identityId", "bDelete" }
--    local _result = db:multi_hget(key, unpack(keys))
--    return _result;
--end
--
---------------------------------------------------------------------------------
-- 分页获取回复帖
-- @param #string bbsid
-- @param #string forumid
-- @param #string topicid 主帖id
-- @param #string pagenum 页.
-- @param #string pagesize 每页显示条数.
-- @result #table  {list=list,totalRow=totalRow,totalPage=totalPage}
function BbsPostService:getPostsFromDb(bbsid, forumid, topicid, pagenum, pagesize,sort)
--    if bbsid == nil or string.len(bbsid) == 0 then
--        error("bbs id 不能为空");
--    end
--    if forumid == nil or string.len(forumid) == 0 then
--        error("forum id 不能为空");
--    end
    if topicid == nil or string.len(topicid) == 0 then
        error("topic id 不能为空");
    end
    if pagenum == nil or string.len(pagenum) == 0 then
        error("pagenum  不能为空");
    end
    if pagesize == nil or string.len(pagesize) == 0 then
        error("pagesize  不能为空");
    end
    local db = SsdbUtil:getDb()
    local topic_keys = { "forumId", "forumName", "title", "content", "personId", "personName", "createTime", "bReply", "viewCount", "replyCount", "identityId", "bBest", "bTop" }
    local topic_key = "social_bbs_topicid_" .. topicid
    local topicResult = db:multi_hget(topic_key, unpack(topic_keys))
    --util:log_r_keys(topic_key, "multi_hget")
    log.debug(topicResult)
    local topic = {}
    if topicResult and #topicResult > 0 then
        local _topic = util:multi_hget(topicResult, topic_keys)
        --topic.forum_name = _topic.forumName;
        topic.forum_id = _topic.forumId;
        topic.title = _topic.title;
        topic.content = _topic.content;
        topic.person_id = _topic.personId;
        topic.person_name = _topic.personName
        topic.createTime = _topic.createTime;
        topic.b_reply = _topic.bReply;
        topic.view_count = _topic.viewCount;
        topic.reply_count = _topic.replyCount;
        topic.icon_url = getIcon(_topic.personId, _topic.identityId)
        topic.b_best = _topic.bBest;
        topic.b_top = _topic.bTop;
        local forumResult = db:multi_hget("social_bbs_forum_" .. _topic.forumId, "name")
        if forumResult and #forumResult > 0 then
            topic.forum_name = forumResult[2]
        end
        topic.reply_list = {}
        local bbsidFilter = ((bbsid == nil or string.len(bbsid) == 0) and "") or "filter=bbs_id," .. bbsid .. ";"
        local forumidFilter =((forumid == nil or string.len(forumid) == 0) and "") or "filter=forum_id," .. forumid .. ";"
        local topicidFilter = "filter=topic_id," .. topicid .. ";"
        local filter = bbsidFilter .. forumidFilter .. topicidFilter
        local orderStr = "attr_asc:ts;";
        if sort == "1" then
            orderStr =  "attr_desc:ts;";
        end
        local res, totalRow, totalPage = getPostSphinxData(filter, pagenum, pagesize,orderStr);
        topic.totalRow = totalRow;
        topic.totalPage = totalPage;
        topic.pageNumber = pagenum;
        topic.pageSize = pagesize;
        if res then
            for i = 1, #res do
                local key = "social_bbs_postid_" .. res[i]["id"]
                local keys = { "id", "content", "personId", "personName", "createTime", "floor", "identityId", "bDelete","parentId" }
                local _result = db:multi_hget(key, unpack(keys))
                if _result and #_result > 0 then
                    local _post = util:multi_hget(_result, keys)
                    local t = {}
                    t.id = _post.id
                    t.person_id = _post.personId;
                    t.person_name = _post.personName
                    t.identity_id = _post.identityId
                    t.create_time = _post.createTime;
                    t.icon_url = getIcon(_post.personId, _post.identityId)
                    t.floor = _post.floor;
                    t.content = _post.content
                    t.b_delete = _post.bDelete;
                    t.parent_id = _post.parentId
                    local key_p = "social_bbs_postid_" .. _post.parentId
                    local keys_p = { "id", "content", "personId", "personName", "createTime", "floor", "identityId", "bDelete" }
                    local _result_p = db:multi_hget(key_p, unpack(keys_p))
                    if _result_p and #_result_p > 0 then
                        local _post_p = util:multi_hget(_result_p, keys_p)
                        t.parent_identity_id = _post_p.identityId
                        t.parent_person_name = _post_p.personName;
                        t.parent_person_id = _post_p.personId
                    end
                    table.insert(topic.reply_list, t)
                end
            end
        end
    else
        log.debug("---------------------------------")
        topic.totalRow = 0;
        topic.totalPage = 0;
        topic.pageNumber = pagenum;
        topic.pageSize = pagesize;
    end
    return topic;
end

---------------------------------------------------------------------------------------------
-- 通过回复帖id删除回复帖 mysql
--
function BbsPostService:deletPostByIdToDb(postid)
    if postid == nil or string.len(postid) == 0 then
        error("postid不能为空.")
    end
    local update_ts = TS.getTs()
    local sql = "UPDATE T_SOCIAL_BBS_POST SET B_DELETE=1,UPDATE_TS=" .. update_ts .. " WHERE ID=" .. postid
    local queryResult = DBUtil:querySingleSql(sql);
    return queryResult;
end

---------------------------------------------------------------------------------------------
-- 通过回复帖id删除回复帖 ssdb
--
function BbsPostService:deletPostByIdToSsDb(topicid, postid)
    if postid == nil or string.len(postid) == 0 then
        error("postid不能为空.")
    end
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid不能为空.")
    end
    local db = SsdbUtil:getDb()
    local key = "social_bbs_postid_" .. postid
    -- local key = "social_bbs_topicid_" .. topicid .. "_postid_" .. postid
    local status, err = db:multi_hset(key, "bDelete", 1)
    if status then
        return true;
    end
    return false;
end

--------------------------------------------------------------------------------------------
-- 通过用户信息查询回复帖信息.
-- @param #string personId.
-- @param #string identityId.
-- @param #string pagenum.
-- @param #string pagesize.
function BbsPostService:getPostListByUserInfo(personId, identityId,messageType, pagenum, pagesize)
    log.debug("personId:" .. personId)
    if personId == nil or string.len(personId) == 0 then
        error("person_id 不能为空.")
    end
    if identityId == nil or string.len(identityId) == 0 then
        error("identity_id 不能为空.")
    end
    if messageType == nil or string.len(messageType) == 0 then
        error("message_type不能为空.")
    end
    if pagenum == nil or string.len(pagenum) == 0 then
        error("pagenum  不能为空");
    end
    if pagesize == nil or string.len(pagesize) == 0 then
        error("pagesize  不能为空");
    end
    local personIdFilter = "filter=person_id," .. personId .. ";"
    local identityIdFilter = "filter=identity_id," .. identityId .. ";"
    local messageTypeFilter =  "filter=message_type," .. messageType .. ";"
    local deleteFilter = "filter=b_delete,0;"
    local filter = personIdFilter .. identityIdFilter..messageTypeFilter..deleteFilter
    local res, totalRow, totalPage = getPostSphinxData(filter, pagenum, pagesize,"attr_desc:ts;");
    local post = {}
    post.totalRow = totalRow;
    post.totalPage = totalPage;
    post.pageNumber = pagenum;
    post.pageSize = pagesize;
    post.list = {}
    local db = SsdbUtil:getDb()
    if res then
        for i = 1, #res do
            -- local key = "social_bbs_topicid_" .. topicid .. "_postid_" .. res[i]["id"]
            local key = "social_bbs_postid_" .. res[i]["id"]
            local keys = { "id", "content", "personId", "personName", "createTime", "floor", "identityId", "bDelete" ,"bbsId","topicId","forumId"}
            local _result = db:multi_hget(key, unpack(keys))
            if _result and #_result > 0 and _result[1]~="ok" then
                local _post = util:multi_hget(_result, keys)
                local t = {}
                t.id = _post.id
                t.create_time = _post.createTime;
                t.icon_url = getIcon(_post.personId, _post.identityId)
                t.floor = _post.floor;
                t.content = _post.content
                t.b_delete = _post.bDelete;
                t.bbs_id=_post.bbsId;
                t.forum_id = _post.forumId
                local topic_key = "social_bbs_topicid_" .. _post.topicId
                local topic_keys = {"title","personId","personName","identityId"}
                local topic_result = db:multi_hget(topic_key, unpack(topic_keys))
                if topic_result and #topic_result > 0 then
                    local _topic = util:multi_hget(topic_result, topic_keys)
                    t.person_id = _topic.personId;
                    t.person_name = _topic.personName;
                    t.topic_title =_topic.title;
                    t.identity_id = _topic.identityId
                end
                t.topic_id = _post.topicId;
                table.insert(post.list, t)
            end
        end
    end
    return post
end

return BbsPostService;
