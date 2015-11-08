--
--    张海  2015-05-06
--    描述：  BBS service 接口.
--
local SsdbUtil = require("social.common.ssdbutil")
local util = require("social.common.util")
local date = require("social.common.date")
local log = require("social.common.log")
local len = string.len
local M = {}
local BbsTotalService = M

------------------------------------------------------------------------------------------------------------------------
-- 设置此模块今日主题帖数.
-- @param #string bbsid bbsid
-- @param #string forumid forumid
function M:addForumTopicCurrentDateNumber(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local currentDate = os.date("%Y%m%d")
    local today_key_template = "social_bbs_%s_forum_%s_today_%s_topicnumber";
    local history_key_template = "social_bbs_%s_forum_%s_history_topicnumber"; --总
    local today_key = string.format(today_key_template, bbsid, forumid, currentDate);
    local history_key = string.format(history_key_template, bbsid, forumid);
    log.debug("设置此模块今日主帖数：key:" .. today_key)
    util:logkeys(today_key, "set")
    util:logkeys(history_key, "set")
    local db = SsdbUtil:getDb();
    local isTodayExists = db:exists(today_key);
    local isHistoryExists = db:exists(history_key);
    if isTodayExists then ----------------- 今天主题帖数加1
        db:incr(today_key, 1);
    else
        db:set(today_key, 1)
    end
    if isHistoryExists then ----------------- 总主题帖数加1
        db:incr(history_key, 1);
    else
        db:set(history_key, 1)
    end
    local historyvalue = db:get(history_key)
    -------------------------------------------------------
    -- 删除前天的数据.
    local b_yesterday = tostring(date(os.date("%Y%m%d")):adddays(-2):fmt("%Y%m%d"))
    local b_yesterday_key = string.format(today_key_template, bbsid, forumid, b_yesterday); --前天的key
    log.debug("设置此模块前天主帖数：key:" .. b_yesterday_key)
    util:logkeys(b_yesterday_key, "set")
    local isBYesterdayExists = db:exists(b_yesterday_key);
    if isBYesterdayExists then
        db:del(b_yesterday_key); --删除前天的数据.
    end
end

------------------------------------------------------------------------------------------------------------------------
-- 获取此模块总主题帖数.
-- @param #string bbsid bbsid
-- @param #string forumid forumid
function M:getForumTopicHistoryNumber(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local history_key_template = "social_bbs_%s_forum_%s_history_topicnumber"
    local history_key = string.format(history_key_template, bbsid, forumid);
    log.debug("获取此模块总主帖数：history_key:" .. history_key)
    local db = SsdbUtil:getDb();
    local count = db:get(history_key)
    log.debug(count)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end

------------------------------------------------------------------------------------------------------------------------
-- 获取此模块今天主题帖数.
-- @param #string bbsid bbsid
-- @param #string forumid forumid
function M:getForumTopicCurrentDateNumber(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local currentDate = tostring(os.date("%Y%m%d"))
    local key = "social_bbs_%s_forum_%s_today_%s_topicnumber";
    key = string.format(key, bbsid, forumid, currentDate);
    log.debug("获取此模块今天主帖数：key:" .. key)
    local db = SsdbUtil:getDb();
    local count = db:get(key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end

------------------------------------------------------------------------------------------------------------------------
-- 获取此模块昨天主题帖数.
-- @param #string bbsid bbsid
-- @param #string forumid forumid
function M:getForumTopicYestdayNumber(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end

    local yestoday = tostring(date(os.date("%Y%m%d")):adddays(-1):fmt("%Y%m%d"))
    local key = "social_bbs_%s_forum_%s_today_%s_topicnumber";
    key = string.format(key, bbsid, forumid, yestoday);
    log.debug("获取此模块昨天天主帖数：key:" .. key)
    local db = SsdbUtil:getDb();
    local count = db:get(key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end

--------------------------------------------------------------------------------
-- 设置今天的回帖数.
-- @param #string bbsid
-- @param #string forumid
function M:addForumPostCurrentDateNum(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local currentDate = tostring(os.date("%Y%m%d"))
    local keytemplate = "social_bbs_%s_forum_%s_today_%s_postnumber";
    local history_key_template = "social_bbs_%s_forum_%s_history_postnumber"; --总

    local key = string.format(keytemplate, bbsid, forumid, currentDate);
    util:logkeys(key, "set")
    local history_key = string.format(history_key_template, bbsid, forumid);
    log.debug("addForumPostCurrentDateNum :设置此模块今日回帖数：key:" .. key)
    log.debug("addForumPostCurrentDateNum :设置此模块历史回帖数：key:" .. history_key)
    util:logkeys(history_key, "set")
    local db = SsdbUtil:getDb();
    local isTodayExists = db:exists(key);
    local isHistoryExists = db:exists(key);
    if isTodayExists then ----------------- 今天回帖数加1
        db:incr(key, 1);
    else
        db:set(key, 1)
    end
    if isHistoryExists then ----------------- 总回帖数加1
        db:incr(history_key, 1);
    else
        db:set(history_key, 1)
    end
end

--------------------------------------------------------------------------------
-- 获取当天回帖数
function M:getForumPostCurrentDateNum(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local currentDate = tostring(os.date("%Y%m%d"))
    local key = "social_bbs_%s_forum_%s_today_%s_postnumber";
    key = string.format(key, bbsid, forumid, currentDate);
    log.debug("getForumPostCurrentDateNum: 设置此模块今日回帖数：key:" .. key)
    local db = SsdbUtil:getDb();
    local count = db:get(key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end

--------------------------------------------------------------------------------
-- 获取历史回帖数
function M:getForumPostHistoryNum(bbsid, forumid)

    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local history_key = "social_bbs_%s_forum_%s_history_postnumber"
    history_key = string.format(history_key, bbsid, forumid);

    local db = SsdbUtil:getDb();
    local count = db:get(history_key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end

--------------------------------------------------------------------------------
-- 获取昨天回帖数
function M:getForumPostYestdayNum(bbsid, forumid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid 不能为空.")
    end
    local yestoday = tostring(date(os.date("%Y%m%d")):adddays(-1):fmt("%Y%m%d")) --计算昨天时间
    local key = "social_bbs_%s_forum_%s_today_%s_postnumber"; --可以用今天的key
    key = string.format(key, bbsid, forumid, yestoday);
    log.debug("getForumPostHistoryNum:设置此模块昨天回帖数：key:" .. key)
    local db = SsdbUtil:getDb();
    local count = db:get(key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end

    return number;
end


--------------------------------------------------------------------------------
-- 设置此bbs论坛的今日总贴数
function M:addPostNumber(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    local currentDate = tostring(os.date("%Y%m%d"))
    local keytemplate = "social_bbs_%s_totay_%s_total"
    local key = string.format(keytemplate, bbsid, currentDate);
    util:logkeys(key, "set")
    local history_key_template = "social_bbs_%s_history_total"
    local history_key = string.format(history_key_template, bbsid)
    util:logkeys(history_key, "set")
    log.debug("添加总帖数key:" .. key)
    log.debug("添加历史总帖数key:" .. key)
    local db = SsdbUtil:getDb();
    local val = db:get(key)
    log.debug(val)
    log.debug(val[1])
    if val and val[1] and len(val[1]) > 0 then
        db:incr(key, 1);
    else
        local status, err = db:set(key, 1)
    end

--    local isHistoryExists = db:exists(history_key);
--    if isHistoryExists then
--        db:incr(history_key, 1);
--    else
--        db:set(history_key, 1)
--    end
    db:hincr("social_bbs_" .. bbsid, 'total_post', 1);--总帖数加1
    -------------------------------------------------------
    -- 删除前天的数据.
    local b_yesterday = tostring(date(os.date("%Y%m%d")):adddays(-2):fmt("%Y%m%d"))
    local b_yesterday_key = string.format(keytemplate, bbsid, b_yesterday); --前天的key
    log.debug("设置此论坛前天总帖数：key:" .. b_yesterday_key)
    util:logkeys(b_yesterday_key, "set")
    local isBYesterdayExists = db:exists(b_yesterday_key);
    if isBYesterdayExists then
        db:del(b_yesterday_key); --删除前天的数据.
    end
end

-------------------------------------------------------------------------
--设置总主题帖数
function M:addTopicTotalNumber(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    local db = SsdbUtil:getDb();
    local status =  db:hincr("social_bbs_" .. bbsid, 'total_topic', 1);--总帖数加1

    log.debug("总主题帖数加1: "..tostring(status));
end


--------------------------------------------------------------------------------
-- 获取此bbs论坛的今天总贴数
function M:getCurrentDatePostTotal(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    local currentDate = tostring(os.date("%Y%m%d"))
    local key = "social_bbs_%s_totay_%s_total"
    key = string.format(key, bbsid, currentDate);
    log.debug("获取此论坛今日帖数：key:" .. key)
    local db = SsdbUtil:getDb();
    local count = db:get(key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end

------------------------------------------------------------------------------------------------------------------------
-- 获取此bbs论坛的昨天总贴数
function M:getYestoryPostTotal(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    local yestoday = tostring(date(os.date("%Y%m%d")):adddays(-1):fmt("%Y%m%d"))
    local key = "social_bbs_%s_totay_%s_total"
    key = string.format(key, bbsid, yestoday);
    log.debug("获取此论坛今日帖数：key:" .. key)
    local db = SsdbUtil:getDb();
    local count = db:get(key)
    local number = 0;
    if count and count[1] and string.len(count[1]) > 0 then
        number = tonumber(count[1]);
    end
    return number;
end


--------------------------------------------------------------------------------
-- 获取此bbs论坛的历史总贴数
function M:getHistoryPostTotal(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
--    local history_key = "social_bbs_%s_history_total"
--    history_key = string.format(history_key, bbsid);
--    log.debug("获取此论坛历史总帖数：key:" .. history_key)
--    local db = SsdbUtil:getDb();
--    local count = db:get(history_key)
--    local number = 0;
--    if count and count[1] and string.len(count[1]) > 0 then
--        number = tonumber(count[1]);
--    end
--    return number;
    local db = SsdbUtil:getDb();
    local totala = db:hget("social_bbs_" .. bbsid, "total_post");
    local number = 0;
    if totala and totala[1] and string.len(totala[1]) > 0 then
        number = tonumber(totala[1]);
    end
    return number;
end

----------------------------------------------------------------------------------
--获取此bbs论坛的历史总主题贴数
function M:getTopicTotalNumber(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    local db = SsdbUtil:getDb();
    local totala = db:hget("social_bbs_" .. bbsid, "total_topic");
    local number = 0;
    log.debug(totala)
    if totala and totala[1] and string.len(totala[1]) > 0 then
        number = tonumber(totala[1]);
    end
    return number;
end

return BbsTotalService;
