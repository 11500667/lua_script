--
--    张海  2015-05-06
--    描述：  BBSTopicService 接口. 主题帖操作。
--
local util = require("social.common.util")
local DBUtil = require "common.DBUtil";
local SsdbUtil = require("social.common.ssdbutil")
local TableUtil = require("social.common.table")
local date = require("social.common.date")
local log = require("social.common.log")
local cjson = require "cjson"
local TS = require "resty.TS"
--local BbsTopicService = {}
local M = {}
local BbsTopicService = M
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

local function convertTopic(topic)
    local create_ts = TS.getTs()
    local typeid = ((topic.typeId == nil or string.len(topic.typeId) == 0) and "bbs_" .. topic.bbsId) or topic.typeId
    local t = {
        ID = topic.id,
        BBS_ID = topic.bbsId,
        FORUM_ID = topic.forumId,
        TITLE = ngx.quote_sql_str(topic.title),
        FIRST_POST_ID = topic.firstPostId,
        PERSON_ID = topic.personId,
        IDENTITY_ID = topic.identityId,
        PERSON_NAME = ngx.quote_sql_str(topic.personName),
        CREATE_TIME = "now()",
        TS = create_ts,
        UPDATE_TS = create_ts,
        LAST_POST_ID = topic.lastPostId,
        REPLYER_PERSON_ID = topic.replyerPersonId,
        REPLYER_IDENTITY_ID = topic.replyerIdentityId,
        REPLYER_TIME = "now()",
        VIEW_COUNT = topic.viewCount,
        CONTENT = ngx.quote_sql_str(topic.content),
        REPLY_COUNT = topic.replyCount,
        B_REPLY = topic.bReply,
        CATEGORY_ID = topic.categoryId,
        B_BEST = topic.bBest,
        B_TOP = topic.bTop,
        SUPPORT_COUNT = topic.supportCount,
        OPPOSE_COUNT = topic.opposeCount,
        B_DELETE = topic.bDelete,
        MESSAGE_TYPE = topic.messageType,
        TYPE_ID = ngx.quote_sql_str(typeid)
    }
    log.debug("保存主题帖信息数据Table:");
    log.debug(t)
    return t
end

--------------------------------------------------------------------------------
-- 获取主键
function M:getTopicPkId()
    local db = SsdbUtil:getDb();
    local topicid = db:incr("social_bbs_topic_pk")[1]
    util:logkeys("social_bbs_topic_pk", "") --把key记录到日志文件 中.
    return topicid
end

--------------------------------------------------------------------------------
-- 保存主题帖信息(保存到MariaDB数据库)
-- @param table topic
-- @return
function M:saveTopic(topic)
    if topic == nil or TableUtil:length(topic) == 0 then
        error("topic is null");
    end
    --local sql = "INSERT INTO `T_SOCIAL_BBS_TOPIC` (`ID`, `BBS_ID`, `FORUM_ID`, `TITLE`, `FIRST_POST_ID`, `PERSON_ID`, `IDENTITY_ID`, `PERSON_NAME`, `CREATE_TIME`, `LAST_POST_ID`, `REPLYER_PERSON_ID`, `REPLYER_IDENTITY_ID`, `REPLYER_TIME`, `VIEW_COUNT`, `CONTENT`, `REPLY_COUNT`, `B_REPLY`, `CATEGORY_ID`, `B_BEST`, `B_TOP`, `SUPPORT_COUNT`, `OPPOSE_COUNT`) VALUES"
    --local values ="(1, 0, 0, '', 0, 0, NULL, NULL, '2015-05-07 14:01:52', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)";
    topic.bDelete = 0;
    local tempTopic = convertTopic(topic)
    local column = {}
    local fileds = {}
    for key, var in pairs(tempTopic) do
        if tempTopic[key] then
            addTable(tempTopic, key, column, fileds)
        end
    end
    local sql = splitAddSql(column, fileds, "T_SOCIAL_BBS_TOPIC")
    log.debug("保存主题帖信息sql:" .. sql);
    return DBUtil:querySingleSql(sql);
end

--- 保存主题帖信息(保存到SSDB数据库)
-- @param table topic
-- @return
function M:saveTopicToSsdb(topic)
    if topic == nil or TableUtil:length(topic) == 0 then
        error("topic is null");
    end
    --    if topic.forumId == nil or string.len(topic.forumId) == 0 then
    --        error("forum id is null");
    --    end
    topic.createTime = os.date("%Y-%m-%d %H:%M:%S")
    local db = SsdbUtil:getDb();
    topic.bDelete = 0;
    local key = "social_bbs_topicid_" .. topic.id
    log.debug("保存主题帖的 key:" .. key)

    db:multi_hset(key, topic)

    if topic.typeId ~= nil then
        local topic_typeid_key = "social_bbs_typeid_" .. topic.typeId
        db:set(topic_typeid_key, topic.id);
        util:logkeys(key, "multi_hset") --把key记录到日志文件 中.
    end
    --    local topicids_t, err = db:hget("social_bbs_forum_include_topic", "forum_id_" .. topic.forumId)
    --    util:log_r_keys("social_bbs_forum_include_topic", "hget")
    --    local topicids = ""
    --    if topicids_t and string.len(topicids_t[1]) > 0 then
    --        topicids = topicids_t[1] .. "," .. topic.id
    --    else
    --        topicids = topic.id
    --    end
    --    db:hset("social_bbs_forum_include_topic", "forum_id_" .. topic.forumId, topicids)
    --    util:logkeys("social_bbs_forum_include_topic", "hset")
end

--------------------------------------------------------------------------------
-- 回复时修改主题表数据(ssdb)
-- @param #string topicid 主题id.
-- @param #string lastPostId 最后回帖id.
-- @param #string replyerPersonId 回复人id.
-- @param #string replyerIdentityId 回复人身份id.
-- @param #string replyerPersonName 回复人name.
function M:updateTopicToSsdb(topicid, lastPostId, replyerPersonId, replyerIdentityId, replyerPersonName)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid is null");
    end
    if lastPostId == nil or string.len(lastPostId) == 0 then
        error("lastPostId is null");
    end
    if replyerPersonId == nil or string.len(replyerPersonId) == 0 then
        error("replyerPersonId is null");
    end
    if replyerIdentityId == nil or string.len(replyerIdentityId) == 0 then
        error("replyerIdentityId is null");
    end
    local db = SsdbUtil:getDb();
    local key = "social_bbs_topicid_" .. topicid
    local keys = { "lastPostId", "replyerPersonId", "replyerIdentityId", "replyCount", "replyerTime", "replyerPersonName" }
    local topicResult = db:multi_hget(key, unpack(keys))
    util:log_r_keys(key, "hget")
    if topicResult and #topicResult > 0 then
        local _topic = util:multi_hget(topicResult, keys)
        log.debug("updateTopicToSsdb")
        log.debug("回复信息后，修改主题帖缓存")
        log.debug(_topic)
        local replyCount = 0;
        if _topic.replyCount ~= "" then
            replyCount = tonumber(_topic.replyCount) + 1 --回复总次数加1次
        else
            replyCount = 1
        end
        local _temp = {}
        _temp.replyCount = replyCount;
        _temp.lastPostId = lastPostId;
        _temp.replyerPersonId = replyerPersonId;
        _temp.replyerIdentityId = replyerIdentityId;
        _temp.replyerPersonName = replyerPersonName;
        _temp.lastPostName = replyerPersonName;
        local date = os.date("%Y-%m-%d %H:%M:%S");
        _temp.replyerTime = date
        log.debug(_temp)
        db:multi_hset(key, _temp)
        util:logkeys(key, "multi_hset")
        -- db:hincr(key, "replyCount", 1); --回复总次数加1次
    end
end

--------------------------------------------------------------------------------
-- 回复时修改主题表数据(ssdb)
-- @param #string topicid 主题id.
-- @param #string lastPostId 最后回帖id.
-- @param #string replyerPersonId 回复人id.
-- @param #string replyerIdentityId 回复人身份id.
function M:updateTopicToDb(topicid, lastPostId, replyerPersonId, replyerIdentityId, replyerPersonName)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid is null");
    end
    if lastPostId == nil or string.len(lastPostId) == 0 then
        error("lastPostId is null");
    end

    if replyerPersonId == nil or string.len(replyerPersonId) == 0 then
        error("replyerPersonId is null");
    end
    if replyerIdentityId == nil or string.len(replyerIdentityId) == 0 then
        error("replyerIdentityId is null");
    end


    local replyCount
    local sql = "UPDATE T_SOCIAL_BBS_TOPIC ";
    sql = sql .. "SET CREATE_TIME=CREATE_TIME,LAST_POST_ID=" .. lastPostId .. ",REPLYER_PERSON_ID=" .. replyerPersonId .. ",REPLYER_IDENTITY_ID =" .. replyerIdentityId .. ",replyer_time=now(),REPLY_COUNT=REPLY_COUNT+1"
    sql = sql .. " WHERE ID=" .. topicid
    local topicResult = DBUtil:querySingleSql(sql);
    return topicResult;
end





--------------------------------------------------------------------------------
-- 查看时修改主题表数据(ssdb)
-- @param topicid #string 主题id.
function M:updateTopicViewCountToSsdb(topicid)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid is null");
    end
    local db = SsdbUtil:getDb();
    local key = "social_bbs_topicid_" .. topicid
    log.debug("查看时的topicid key:" .. key);
    util:log_r_keys(key, "multi_hget")
    local keys = { "viewCount" }
    local topicResult = db:hexists(key, unpack(keys));
    if topicResult then
        db:hincr(key, "viewCount", 1); --回复总次数加1次
    end
end

--------------------------------------------------------------------------------
-- 查看时修改主题表数据(ssdb)
-- @param #string topicid   主题id.
function M:updateTopicViewCountToDb(topicid)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid is null");
    end
    local replyCount
    local sql = "UPDATE T_SOCIAL_BBS_TOPIC ";
    sql = sql .. "SET VIEW_COUNT=VIEW_COUNT+1"
    sql = sql .. " WHERE ID=" .. topicid
    local topicResult = DBUtil:querySingleSql(sql);
    return topicResult;
end

--------------------------------------------------------------------------------
-- 获取主题帖列表.
-- @param #string bbsid 论坛id.
-- @param #string forumid 板块id.
-- @param #string categoryid 板块分类id.
-- @param #int pagenum 页
-- @param #int pagesize 每页显示条数.
-- @result #table  {list=list,totalRow=totalRow,totalPage=totalPage}
function M:getTopics(bbsid, forumid, categoryid, pagenum, pagesize)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbs id 不能为空");
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forum id 不能为空");
    end

    local categorySql = (categoryid ~= nil and string.len(categoryid) > 0) and " AND T.CATEGORY_ID=" .. categoryid or ""
    local count_sql = "SELECT COUNT(*)  as totalRow FROM T_SOCIAL_BBS_TOPIC T WHERE T.BBS_ID=" .. bbsid .. " AND T.FORUM_ID=" .. forumid .. categorySql
    local list_sql = "SELECT *  FROM T_SOCIAL_BBS_TOPIC T WHERE T.BBS_ID=" .. bbsid .. " AND T.FORUM_ID=" .. forumid .. categorySql
    log.debug("获取主题帖列表.count_sql:" .. count_sql);
    local count = DBUtil:querySingleSql(count_sql);
    if TableUtil:length(count) == 0 then
        return nil;
    end
    log.debug("获取主题帖列表.count:" .. count[1].totalRow);

    local _pagenum = tonumber(pagenum)
    local _pagesize = tonumber(pagesize)
    local totalRow = count[1].totalRow
    local totalPage = math.floor((totalRow + _pagesize - 1) / _pagesize)
    local offset = _pagesize * _pagenum - _pagesize
    list_sql = list_sql .. " LIMIT " .. offset .. "," .. _pagesize
    log.debug("获取主题帖列表.list sql:" .. list_sql);
    local list = DBUtil:querySingleSql(list_sql);
    log.debug("获取主题帖列表.list :" .. list);

    local result = { list = list, totalRow = totalRow, totalPage = totalPage }
    return result;
end


--------------------------------------------------------------------------------
local function getBeforeDay(n)
    local date = date(os.date("%Y%m%d%H%M%S")):adddays(n):fmt("%Y%m%d%H%M%S00") .. string.sub(string.format("%14.3f", ngx.now()), 12, 14)
    return date;
end

local function getBeforeMonth(n)
    local date = date(os.date("%Y%m%d%H%M%S")):addmonths(n):fmt("%Y%m%d%H%M%S00") .. string.sub(string.format("%14.3f", ngx.now()), 12, 14)
    return date;
end


-----------------------------------------------------------------------------
-- 获取主题帖列表.
-- @param #string bbsid 论坛id.
-- @param #string forumid 板块id.
-- @param #string categoryid 板块分类id.
-- @param #int pagenum 页
-- @param #int pagesize 每页显示条数.
-- @param #string filterDate 筛选时间
-- @param #string sortType 排序类型.
-- @result #table  {list=list,totalRow=totalRow,totalPage=totalPage}
function M:getTopicsFromSsdb(bbsid, forumid, categoryid, searchText, filterDate, sortType, best, messageType, pagenum, pagesize)

    log.debug("getTopicsFromSsdb")

    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbs id 不能为空");
    end
    local bbsService = require("social.service.BbsService")
    local bbsTotalService = require("social.service.BbsTotalService")
    local offset = pagesize * pagenum - pagesize
    local limit = pagesize
    local str_maxmatches = "10000"
    local queryStr = "%s%s%s%s%s%s%sfilter=b_delete,0;%smaxmatches=" .. str_maxmatches .. ";offset=" .. offset .. ";limit=" .. limit .. ""
    local sql = "SELECT SQL_NO_CACHE id FROM T_SOCIAL_BBS_TOPIC_SPHINXSE WHERE query=%s;SHOW ENGINE SPHINX  STATUS;"
    local bbsidFilter = "filter=bbs_id," .. bbsid .. ";"
    local forumidFilter = ((forumid == nil or string.len(forumid) == 0) and "") or "filter=forum_id," .. forumid .. ";"
    messageType = ((messageType == nil or string.len(messageType) == 0) and "1") or messageType
    local messageTypeFilter = "filter=message_type," .. messageType .. ";"
    local categoryidFilter = ((categoryid == nil or string.len(categoryid) == 0) and "") or "filter=category_id," .. categoryid .. ";"
    local bestFilter = ((best == nil or string.len(best) == 0) and "") or "filter=b_best,1;"
    local searchTextFilter = ((searchText == nil or string.len(searchText) == 0) and "") or searchText .. ";"

    --sort = sort.."b_top desc,b_best desc";
    local currentDate = TS.getTs() --今天
    local beforeDate = "";
    if filterDate == "1" then
        beforeDate = getBeforeDay(-1) --昨天
    elseif filterDate == "2" then
        beforeDate = getBeforeDay(-2) --前两天
    elseif filterDate == "3" then
        beforeDate = getBeforeDay(-7) --前一周
    elseif filterDate == "4" then
        beforeDate = getBeforeMonth(-1) --前一个月
    elseif filterDate == "5" then
        beforeDate = getBeforeMonth(-3) --前三个月
    end

    --sort=extended:ts desc,b_top desc,b_best desc ;
    --local sort = "sort=attr_desc:"
    local sort = "sort=extended:b_top desc,"
    if not sortType or string.len(sortType) == 0 or sortType == "1" then
        sort = sort .. "ts desc;"
    elseif sortType == "2" then
        sort = sort .. "reply_count desc;"
    elseif sortType == "3" then
        sort = sort .. "view_count desc;"
    else
        sort = sort .. "ts desc;"
    end



    local _filterDate = ((filterDate == nil or string.len(filterDate) == 0 or filterDate == "0") and "") or "select=(IF(ts>" .. beforeDate .. ",1,0) AND IF(ts<" .. currentDate .. ",1,0)) as match_qq;filter=match_qq,1;"
    queryStr = string.format(queryStr, searchTextFilter, bbsidFilter, forumidFilter, categoryidFilter, bestFilter, messageTypeFilter, _filterDate, sort);
    queryStr = ngx.quote_sql_str(queryStr)
    log.debug("queryStr :" .. queryStr)
    sql = string.format(sql, queryStr)
    log.debug("sql :" .. sql)
    local db = DBUtil:getDb();
    local res = db:query(sql)
    --去第二个结果集中的Status中截取总个数
    local res1 = db:read_result()
    -- util:logData(res1)
    local _, s_str = string.find(res1[1]["Status"], "found: ")
    local e_str = string.find(res1[1]["Status"], ", time:")
    local totalRow = string.sub(res1[1]["Status"], s_str + 1, e_str - 1)
    local totalPage = math.floor((totalRow + pagesize - 1) / pagesize)
    -- util:logData(res)
    local topic = {}
    topic.pageNumber = pagenum;
    topic.totalPage = totalPage;
    topic.totalRow = totalRow;
    topic.pageSize = pagesize
    topic.bbs = bbsid;
    if forumid ~= nil and string.len(forumid) > 0 then

        topic.total_today = bbsTotalService:getForumTopicCurrentDateNumber(bbsid, forumid);
        topic.total_topic = bbsTotalService:getForumTopicHistoryNumber(bbsid, forumid);

        local forum = bbsService:getForumByIdFromSsdb(forumid)
        topic.forum_name = (forum.name == nil and "") or forum.name
        topic.forum_description = (forum.description == nil and "") or forum.description
        topic.forum_admin_list = (forum.forum_admin_list == "" and "") or cjson.decode(forum.forum_admin_list);
    end
    topic.topic_list = {}
    local db = SsdbUtil:getDb();
    if res then
        for i = 1, #res do
            local key = "social_bbs_topicid_" .. res[i]["id"]
            local keys = { "id", "title", "categoryName", "personId", "personName", "createTime", "replyCount", "viewCount", "lastPostId", "lastPostName", "replyerTime", "replyerPersonName", "bTop", "bBest", "forumId" }
            local _result = db:multi_hget(key, unpack(keys))
            util:log_r_keys(key, "multi_hget")
            log.debug("从ssdb中取出的数据")
            log.debug(_result);
            if _result and #_result > 0 then
                local _topic = util:multi_hget(_result, keys)
                -- util:logData("转换后的数据")
                -- util:logData(_topic);
                local t = {}
                t.id = _topic.id
                t.title = _topic.title;
                t.category_name = _topic.categoryName
                t.person_id = _topic.personId;
                t.person_name = _topic.personName
                t.create_time = _topic.createTime;
                t.replyer_count = _topic.replyCount
                t.view_count = _topic.viewCount
                t.last_post_id = _topic.lastPostId
                -- t.last_post_name = _topic.lastPostName
                t.last_post_name = _topic.replyerPersonName
                t.replyer_time = _topic.replyerTime
                t.replyer_person_name = _topic.replyerPersonName
                t.b_top = _topic.bTop;
                t.b_best = ((_topic.bBest == "" or _topic.bBest == "0") and "0") or _topic.bBest;
                t.forum_id = _topic.forumId
                table.insert(topic.topic_list, t)
            end
        end
    end
    -- util:logData("返回的数据")
    -- util:logData(topic);
    return topic;
end

--------------------------------------------------------------------------------
-- 通过bbsid,forumid,获取分类列表.
-- @param #string bbsid
-- @param #string forumid
-- @return #table result
function M:getBbsTopicCategory(bbsid, forum)
    local sql = "SELECT * FROM T_SOCIAL_BBS_TOPIC_CATEGORY T WHERE T.BBS_ID=%s AND FORUM_ID=%s"
    sql = string.format(sql, bbsid, forum)
    log.debug("通过bbsid,forumid,获取分类列表sql:" .. sql);
    return DBUtil:querySingleSql(sql);
end

--------------------------------------------------------------------------------
-- 通过topicid,设置该主题帖置顶 mysql
-- @param #string topicid
-- @param #boolean isCancel
function M:setTopByIdToDb(topicid, isCancel)
    local sql = "";
    local update_ts = TS.getTs()
    if isCancel then
        sql = "UPDATE T_SOCIAL_BBS_TOPIC SET B_TOP=0,UPDATE_TS=" .. update_ts .. " WHERE ID=" .. topicid
    else
        sql = "UPDATE T_SOCIAL_BBS_TOPIC SET B_TOP=" .. tonumber(os.date("%Y%m%d%H%M%S", os.time())) .. ",UPDATE_TS=" .. update_ts .. " WHERE ID=" .. topicid
    end
    log.debug("设置该主题帖置顶sql:" .. sql);
    return DBUtil:querySingleSql(sql);
end

--------------------------------------------------------------------------------
-- 通过topicid,设置该主题帖置顶 ssdb
-- @param #string topicid
-- @param #boolean isCancel
function M:setTopByIdToSsDb(topicid, isCancel)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid is null");
    end
    local db = SsdbUtil:getDb();
    local key = "social_bbs_topicid_" .. topicid
    log.debug("查看时的topicid key:" .. key);
    util:log_r_keys(key, "multi_hget")
    local keys = { "bTop" }
    if isCancel then
        db:hset(key, "bTop", 0);
    else
        db:hset(key, "bTop", tonumber(os.date("%Y%m%d%H%M%S", os.time())));
    end
end

--------------------------------------------------------------------------------
-- 通过topicid,设置该主题帖精华 mysql
-- @param #string topicid
function M:setBestByIdToDb(topicid, val)
    local update_ts = TS.getTs()
    local sql = "UPDATE T_SOCIAL_BBS_TOPIC SET B_BEST=" .. val .. ",UPDATE_TS=" .. update_ts .. " WHERE ID=" .. topicid
    log.debug("设置该主题帖置顶sql:" .. sql);
    return DBUtil:querySingleSql(sql);
end

function M:setBestByIdToSsDb(topicid, val)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid is null");
    end
    local db = SsdbUtil:getDb();
    local key = "social_bbs_topicid_" .. topicid
    log.debug("查看时的topicid key:" .. key);
    util:log_r_keys(key, "multi_hget")
    local keys = { "bBest" }
    db:hset(key, "bBest", val);
end


---------------------------------------------------------------------------------------------
-- 通过主题帖id删除主题帖 mysql
-- 同时删除主题帖下的回复帖.
--
function M:deletTopicByIdToDb(topicid)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid不能为空.")
    end
    local update_ts = TS.getTs()
    local sql = "UPDATE T_SOCIAL_BBS_TOPIC SET B_DELETE=1,UPDATE_TS=" .. update_ts .. " WHERE ID=" .. topicid
    local queryResult = DBUtil:querySingleSql(sql);
    if queryResult then
        log.debug("删除主题帖id:" .. topicid .. "成功.")
        local sql = "UPDATE T_SOCIAL_BBS_POST SET B_DELETE=1,UPDATE_TS=" .. update_ts .. " WHERE TOPIC_ID=" .. topicid
        local result = DBUtil:querySingleSql(sql);
        if result then
            log.debug("删除主题帖id:" .. topicid .. " 下的回复帖成功.")
        end
    end
    return true;
end

---------------------------------------------------------------------------------------------
-- 通过主题帖id删除主题帖 ssdb
-- 同时删除主题帖下的回复帖.
-- @
function M:deletTopicByIdToSsDb(topicid)
    if topicid == nil or string.len(topicid) == 0 then
        error("topicid不能为空.")
    end
    local db = SsdbUtil:getDb()
    local key = "social_bbs_topicid_" .. topicid
    local status, err = db:multi_hset(key, "bDelete", 1)
    if status then
        log.debug("删除topicid:" .. topicid .. "成功.")
        local postIdsResult = db:hget("social_bbs_forum_topic_include_post", "topic_id_" .. topicid)
        if postIdsResult and string.len(postIdsResult[1]) > 0 then
            local postIdStr = postIdsResult[1]
            local postids = Split(postIdStr, ",")
            for _, pid in pairs(postids) do
                if string.len(pid) > 0 then
                    local service = require("social.service.BbsPostService")
                    local r = service:deletPostByIdToSsDb(topicid, pid)
                    if r then
                        log.debug("删除topicid:" .. topicid .. " postid:" .. pid .. "成功.")
                    else
                        log.debug("删除topicid:" .. topicid .. " postid:" .. pid .. "失败.")
                    end
                end
            end
        end
        return true;
    else
        log.debug("删除topicid:" .. topicid .. "失败.")
        return false;
    end
end

---------------------------------------------------------------------------------------------
-- 根据用户id 身份id获取用户所发的主题帖信息.
-- @param #string person_id
-- @param #string identity_id
-- @param #string pagenum
-- @param #string pagesize
-- @return #table
function M:getTopicListByUserInfo(personId, identityId, messageType, pagenum, pagesize)
    if personId == nil or string.len(personId) == 0 then
        error("person_id不能为空.")
    end
    if identityId == nil or string.len(identityId) == 0 then
        error("identity_id不能为空.")
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
    local offset = pagesize * pagenum - pagesize
    local limit = pagesize
    local str_maxmatches = "10000"
    local queryStr = "%s%s%sfilter=b_delete,0;%smaxmatches=" .. str_maxmatches .. ";offset=" .. offset .. ";limit=" .. limit .. ""
    local sql = "SELECT SQL_NO_CACHE id FROM T_SOCIAL_BBS_TOPIC_SPHINXSE WHERE query=%s;SHOW ENGINE SPHINX  STATUS;"
    local sort = "sort=extended:b_top desc,"
    sort = sort .. "ts desc;"
    local personIdFilter = "filter=person_id," .. personId .. ";"
    local identityIdFilter = "filter=identity_id," .. identityId .. ";"
    local messageTypeFilter = "filter=message_type," .. messageType .. ";"
    queryStr = string.format(queryStr, personIdFilter, identityIdFilter, messageTypeFilter, sort);
    queryStr = ngx.quote_sql_str(queryStr)
    log.debug("queryStr :" .. queryStr)
    sql = string.format(sql, queryStr)
    log.debug("sql :" .. sql)
    local db = DBUtil:getDb();
    local res = db:query(sql)
    --去第二个结果集中的Status中截取总个数
    local res1 = db:read_result()
    local _, s_str = string.find(res1[1]["Status"], "found: ")
    local e_str = string.find(res1[1]["Status"], ", time:")
    local totalRow = string.sub(res1[1]["Status"], s_str + 1, e_str - 1)
    local totalPage = math.floor((totalRow + pagesize - 1) / pagesize)
    local topic = {}
    topic.pageNumber = pagenum;
    topic.totalPage = totalPage;
    topic.totalRow = totalRow;
    topic.pageSize = pagesize
    topic.list = {}
    local db = SsdbUtil:getDb();
    if res then
        for i = 1, #res do
            local key = "social_bbs_topicid_" .. res[i]["id"]
            local keys = { "id", "bbsId", "title", "personId", "personName", "createTime", "replyerTime", "replyerPersonName", "forumId" }
            local _result = db:multi_hget(key, unpack(keys))
            if _result and #_result > 0 then
                local _topic = util:multi_hget(_result, keys)
                local t = {}
                t.id = _topic.id
                t.bbs_id = _topic.bbsId
                t.title = _topic.title;
                t.person_id = _topic.personId;
                t.person_name = _topic.personName
                t.create_time = _topic.createTime
                t.replyer_time = _topic.replyerTime
                t.replyer_person_name = _topic.replyerPersonName
                t.forum_id = _topic.forumId
                table.insert(topic.list, t)
            end
        end
    end
    return topic;
end

-----------------------------------------------------------------------------------
-- 通过typeid 与messageType获取topic数据，确定.唯 一
-- @param #string typeId
-- @param #string messageType
function M:getTopicByTypeIdAndType(typeId, messageType)
    if typeId == nil or string.len(typeId) == 0 then
        error("type_id不能为空.")
    end
    if messageType == nil or string.len(messageType) == 0 then
        error("message_type不能为空.")
    end
    local sql = "SELECT * FROM T_SOCIAL_BBS_TOPIC T WHERE T.TYPE_ID=%s AND T.MESSAGE_TYPE=%s"
    sql = sql:format(ngx.quote_sql_str(typeId), messageType)
    log.debug("getTopicByTypeIdAndType:sql: " .. sql);
    local result = DBUtil:querySingleSql(sql);
    return result;
end

return BbsTopicService;
