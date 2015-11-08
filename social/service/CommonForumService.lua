--
-- Created by IntelliJ IDEA.
-- User: zhanghai
-- Date: 2015/6/16
-- Time: 8:43
-- To change this template use File | Settings | File Templates.
-- 通用版块的service.
local serviceBase = require("social.service.CommonBaseService")
local DBUtil = require "common.DBUtil";
local TableUtil = require("social.common.table")
local SsdbUtil = require("social.common.ssdbutil")
local log = require("social.common.log")
local cjson = require "cjson"
local quote = ngx.quote_sql_str
local _M = {
    operate_ssdb = true
}


local function saveForumToDb(param)
    local db = DBUtil:getDb()
    local forum_t = { param.forum_id, param.bbs_id, param.partition_id, quote(param.name), quote(param.icon_url), quote(param.description), param.sequence, "now()", param.type_id, param.type }
    local isql = "insert into t_social_bbs_forum(id,bbs_id,partition_id,name,icon_url,description,sequence,last_post_time,type_id,type) values(" ..
            table.concat(forum_t, ",") .. ")"
    log.debug("保存板块的sql :" .. isql);
    local queryResult = db:query(isql);
    if not queryResult then
        return 0
    end
    for i = 1, #param.forum_admin_list do
        local forum_admin = param.forum_admin_list[i]
        local person_id = forum_admin.person_id
        local identity_id = forum_admin.identity_id
        local person_name = quote(forum_admin.person_name)
        local sql33 = "insert into t_social_bbs_forum_user(forum_id,person_id,identity_id,person_name,flag)values(" .. param.forum_id .. "," .. person_id .. "," .. identity_id .. "," .. person_name .. ",1)"
        db:query(sql33);
    end
    return queryResult.affected_rows
end

local function saveForumToSSDB(param)
    local db = SsdbUtil:getDb();
    local forum = {}
    forum.id = param.forum_id
    forum.bbs_id = param.bbs_id
    forum.partition_id = param.partition_id
    forum.name = param.name
    forum.icon_url = param.icon_url
    forum.description = param.description
    forum.sequence = param.sequence
    forum.b_delete = 0
    forum.post_today = 0
    forum.post_yestoday = 0
    forum.total_topic = 0
    forum.total_post = 0
    forum.last_post_id = 0
    forum.type_id = param.type_id
    forum.type = param.type;
    forum.forum_admin_list = cjson.encode(param.forum_admin_list)
    db:multi_hset("social_bbs_forum_" .. param.forum_id, forum)
    local fids_t, err = db:hget("social_bbs_include_forum", "partition_id_" .. param.partition_id)
    local fids = ""
    if fids_t and string.len(fids_t[1]) > 0 then
        fids = fids_t[1] .. "," .. param.forum_id
    else
        fids = param.forum_id
    end
    db:hset("social_bbs_include_forum", "partition_id_" .. param.partition_id, fids)
end



------------------------------------------------------------------------------------------------------------------------
-- 保存版块信息.
--- @param #table param.
-- bbs_id=param.bbs_id,
-- partition_id=param.partition_id,
-- name=param.name,
-- icon_url=param.icon_url,
-- description=param.description,
-- sequence=param.sequence,
-- typeid=param.typeid,
-- type=param.type
function _M:saveForum(param)
    self:checkParamIsNull({
        bbs_id = param.bbs_id,
        partition_id = param.partition_id,
        name = param.name,
        icon_url = param.icon_url,
        --description = param.description,
        sequence = param.sequence,
        type_id = param.type_id,
        type = param.type
    })
    local db = SsdbUtil:getDb()
    local forum_id = db:incr("social_bbs_forum_pk")[1]
    param.forum_id = forum_id;
    local row = saveForumToDb(param);
    if row > 0 then
        saveForumToSSDB(param)
    end
    SsdbUtil:keepalive()
    return forum_id;
end

local function updateForumToDb(param)
    local db = DBUtil:getDb()
    local usql = "update t_social_bbs_forum set %s where id = " .. param.forum_id
    local str = "bbs_id=" .. param.bbs_id .. ","
    str = str .. "partition_id=" .. param.partition_id .. ","
    str = str .. "name=" .. ngx.quote_sql_str(param.name) .. ","
    str = str .. "icon_url=" .. ngx.quote_sql_str(param.icon_url) .. ","
    str = str .. "sequence=" .. param.sequence .. ","
    str = ((param.description == nil or string.len(param.description) == 0) and "") or str .. "description=" .. ngx.quote_sql_str(param.description) .. ","
    str = str .. "type_id=" .. ngx.quote_sql_str(param.type_id) .. ","
    str = str .. "type=" .. param.type
    usql = string.format(usql, str)
    log.debug(usql);
    local queryResult = db:query(usql);
    if not queryResult then
        DBUtil:keepDbAlive(db)
        return 0
    end
    --删除版主.
    local usql2 = "update t_social_bbs_forum_user set flag = 0 where forum_id = " .. param.forum_id .. " and flag = 1"
    db:query(usql2);
    for i = 1, #param.forum_admin_list do
        local forum_admin = param.forum_admin_list[i]
        local sql11 = "select * from t_social_bbs_forum_user where forum_id = " .. param.forum_id .. " and person_id = " .. forum_admin.person_id .. " and identity_id = " .. forum_admin.identity_id
        local result11, err = db:query(sql11)
        if result11 and #result11 > 0 then
            local sql22 = "update t_social_bbs_forum_user set flag = 1 where forum_id = " .. param.forum_id .. " and person_id = " .. forum_admin.person_id .. " and identity_id = " .. forum_admin.identity_id
            db:query(sql22)
        else
            local sql33 = "insert into t_social_bbs_forum_user(forum_id,person_id,identity_id,person_name,flag) values (" .. param.forum_id .. "," .. forum_admin.person_id .. "," .. forum_admin.identity_id .. "," .. quote(forum_admin.person_name) .. ",1)"
            db:query(sql33)
        end
    end
    DBUtil:keepDbAlive(db)
    return queryResult.affected_rows
end

local function updateForumToSSDB(param)
    local db = SsdbUtil:getDb();
    local forum_admin_list;
    if param.forum_admin_list ~= nil then
        forum_admin_list = cjson.encode(param.forum_admin_list)
    end
    db:multi_hset("social_bbs_forum_" .. param.forum_id, "name", param.name, "icon_url", param.icon_url, "description", param.description, "sequence", param.sequence, "forum_admin_list", forum_admin_list, "type", param.type, "type_id", param.type_id)
    SsdbUtil:keepalive()
end

------------------------------------------------------------------------------------------------------------------------
-- 修改版块信息.
-- @param #string .
function _M:updateForum(param)
    self:checkParamIsNull({
        bbs_id = param.bbs_id,
        partition_id = param.partition_id,
        name = param.name,
        icon_url = param.icon_url,
        forum_id = param.forum_id,
        -- description = param.description,
        sequence = param.sequence,
        type_id = param.type_id,
        type = param.type
    })
    local row = updateForumToDb(param)
    if row > 0 then
        updateForumToSSDB(param)
    end
end


------------------------------------------------------------------------------------------------------------------------
local function deleteOrRecoveryForumToDb(forum_id, isDelete)
    local ssql = "update t_social_bbs_forum set b_delete = "..isDelete.." where id = " .. forum_id
    local queryResult = DBUtil:querySingleSql(ssql);
    if not queryResult then
        return 0
    end
    return queryResult.affected_rows
end

local function deleteForumToSSDB(forum_id)
    local db = SsdbUtil:getDb();
    db:hset("social_bbs_forum_" .. forum_id, "b_delete", 1)
    local partition_id = db:hget("social_bbs_forum_" .. forum_id, "partition_id")[1]
    local fids = db:hget("social_bbs_include_forum", "partition_id_" .. partition_id)[1]
    if fids and string.len(fids) > 0 then
        fids = string.gsub(fids, forum_id .. ",", "")
        fids = string.gsub(fids, "," .. forum_id, "")
        fids = string.gsub(fids, forum_id, "")
    end
    db:hset("social_bbs_include_forum", "partition_id_" .. partition_id, fids)
    SsdbUtil:keepalive()
end

--删除版块信息.
--@param #string
function _M:deleteForum(forum_id)
    self:checkParamIsNull({
        forum_id = forum_id
    })
    local row = deleteOrRecoveryForumToDb(forum_id, 1)
    if row > 0 then
        deleteForumToSSDB(forum_id)
    end
end

------------------------------------------------------------------------------------------------------------------------
local function recoveryForumToSSDB(forum_id)
    local db = SsdbUtil:getDb()
    db:hset("social_bbs_forum_" .. forum_id, "b_delete", 0)
    local partition_id = db:hget("social_bbs_forum_" .. forum_id, "partition_id")[1]

    local fids = db:hget("social_bbs_include_forum", "partition_id_" .. partition_id)[1]
    if fids and string.len(fids) > 0 then
        local _fids = Split(fids, ",")
        table.insert(_fids, forum_id);
        local newPids = table.concat(_fids, ",");
        db:hset("social_bbs_include_forum", "partition_id_" .. partition_id, newPids)
    end
end

------------------------------------------------------------------------------------------------------------------------
-- 恢复删除的版块.
-- @param #string forum_id.
function _M:recoveryForum(forum_id)
    self:checkParamIsNull({
        forum_id = forum_id
    })
    local row = deleteOrRecoveryForumToDb(forum_id, 0)
    if row > 0 then
        recoveryForumToSSDB(forum_id)
    end
end



------------------------------------------------------------------------------------------------------------------------
-- 通过id获取forum
-- 从数据库读取.
-- @param #string forum_id
-- @return table
function _M:getForumById(forum_id)
    self:checkParamIsNull({
        forum_id = forum_id
    })
    local db = DBUtil:getDb()
    local sql = "select id,bbs_id,partition_id,name,icon_url,description,sequence,type,type_id from t_social_bbs_forum where id = %s"
    sql = string.format(sql, forum_id);
    local queryResult = db:query(sql);

    local ssql2 = "select forum_id,person_id,identity_id,person_name from t_social_bbs_forum_user where forum_id = " .. forum_id .. " and flag = 1"
    local sresult2, err = db:query(ssql2)
    local forum_admin_list = {}
    if sresult2 and #sresult2 > 0 then
        for i = 1, #sresult2 do
            forum_admin_list[#forum_admin_list + 1] = sresult2[i]
        end
    end

    local rr = {}
    if queryResult and #queryResult > 0 then
        rr.forum_id = queryResult[1].id
        rr.partition_id = queryResult[1].partition_id
        rr.bbs_id = queryResult[1].bbs_id
        rr.name = queryResult[1].name
        rr.icon_url = queryResult[1].icon_url
        rr.description = queryResult[1].description
        rr.sequence = queryResult[1].sequence
        rr.type = queryResult[1].type
        rr.type_id = queryResult[1].type_id;
        rr.forum_admin_list = forum_admin_list
    end
    return rr;
end

return serviceBase:inherit(_M):init()

