--
-- Created by IntelliJ IDEA.
-- User: zhanghai
-- Date: 2015/6/16
-- Time: 8:44
-- To change this template use File | Settings | File Templates.
-- 通用分区操作。
local serviceBase = require("social.service.CommonBaseService")
local DBUtil = require "common.DBUtil";
local SsdbUtil = require("social.common.ssdbutil")

local log = require("social.common.log")
local quote = ngx.quote_sql_str
local _M = {
    operate_ssdb = true
}
--local CommonPartitionService = _M;

--保存数据到mysql
local function savePartitionToDb(bbs_id, name, sequence, partition_id, type_id, type)
    local sqlvalue = { partition_id,bbs_id, quote(name), sequence , quote(type_id), quote(type) }
    local isql = "insert into t_social_bbs_partition(id,bbs_id,name,sequence,type_id,type) values(" ..
            table.concat(sqlvalue, ",") .. ")"
    local db = DBUtil:getDb();
    log.debug("添加分区sql:" .. isql)
    local queryResult = db:query(isql);
    DBUtil:keepDbAlive(db);
    if not queryResult then
       return 0
    end
    local rows = queryResult.affected_rows;
    return rows --影响行数.
end

--保存数据到ssdb
local function savePartitionToSSDB(bbs_id, name, sequence, partition_id, type_id, type)
    local db = SsdbUtil:getDb();
    local partition = {}
    partition.id = partition_id
    partition.bbs_id = bbs_id
    partition.name = name
    partition.sequence = sequence
    partition.b_delete = 0
    partition.type_id = type_id
    partition.type = type;
    db:multi_hset("social_bbs_partition_" .. partition_id, partition)
    local pids_t, err = db:hget("social_bbs_include_partition", "bbs_id_" .. bbs_id)

    local pids = ""
    if pids_t and string.len(pids_t[1]) > 0 then
        pids = pids_t[1] .. "," .. partition_id
    else
        pids = partition_id
    end
    log.debug(pids)
    db:hset("social_bbs_include_partition", "bbs_id_" .. bbs_id, pids)
end

------------------------------------------------------------------------------------------------------------------------
-- 保存分区信息.
-- @param #string .
function _M:savePartition(bbs_id, name, sequence, type_id, type)
    self:checkParamIsNull({
        bbs_id = bbs_id,
        name = name,
        sequence = sequence,
        typeid = type_id,
        type = type
    })
    local db = SsdbUtil:getDb();
    local partition_id = db:incr("social_bbs_partition_pk")[1]

    local affected_rows = savePartitionToDb(bbs_id, name, sequence, partition_id, type_id, type)
    log.debug("保存分区，返回行数")
    log.debug(affected_rows)
    if affected_rows > 0 then
        savePartitionToSSDB(bbs_id, name, sequence, partition_id, type_id, type)
    end
    SsdbUtil:keepalive()
    return partition_id;
end


--- -
local function updatePartitionToDb(name, partition_id)
    local db = DBUtil:getDb();
    local usql = "update t_social_bbs_partition set name = " .. quote(name) .. " where id = " .. partition_id
    log.debug("修改分区信息sql:" .. usql);
    local uresutl, err = db:query(usql)
    DBUtil:keepDbAlive(db);
    if not uresutl then
        return 0
    end
    local rows = uresutl.affected_rows;
    log.debug("响应行数." .. rows);
    return rows; --影响行数.
end

local function updatePartitionToSSDB(name, partition_id)
    local db = SsdbUtil:getDb();
    db:hset("social_bbs_partition_" .. partition_id, "name", name)
    SsdbUtil:keepalive()
end

------------------------------------------------------------------------------------------------------------------------
-- 修改分区信息.
-- @param #string .
function _M:updatePartition(name, partition_id)
    self:checkParamIsNull({
        name = name,
        partition_id = partition_id
    })
    local rows = updatePartitionToDb(name, partition_id)
    if rows > 0 then
        updatePartitionToSSDB(name, partition_id)
    end
end

local function deleteORRecoveryPartitionToDb(partition_id,isDelete)
    local sql = "update t_social_bbs_partition set b_delete = "..isDelete.." where id = " .. partition_id
    log.debug("删除分区sql:" .. sql);
    local queryResult = DBUtil:querySingleSql(sql);
    if not queryResult then
        return 0
    end
    return queryResult.affected_rows
end

local function deletePartitionToSSDB(partition_id)
    local db = SsdbUtil:getDb()
    db:hset("social_bbs_partition_" .. partition_id, "b_delete", 1)
    local bbs_id, err = db:hget("social_bbs_partition_" .. partition_id, "bbs_id")[1]
    local pids, err = db:hget("social_bbs_include_partition", "bbs_id_" .. bbs_id)[1]
    if pids and string.len(pids) > 0 then
        pids = string.gsub(pids, partition_id .. ",", "")
        pids = string.gsub(pids, "," .. partition_id, "")
        pids = string.gsub(pids, partition_id, "")
    end
    db:hset("social_bbs_include_partition", "bbs_id_" .. bbs_id, pids)
end

------------------------------------------------------------------------------------------------------------------------
--
-- 删除分区信息.
-- @param #string partition_id
function _M:deletePartition(partition_id)
    self:checkParamIsNull({
        partition_id = partition_id
    })
    local row = deleteORRecoveryPartitionToDb(partition_id,1)
    if row > 0 then
        deletePartitionToSSDB(partition_id)
    end
    SsdbUtil:keepalive()
end

local function recoveryPartitionToSSDB(partition_id)
    local db = SsdbUtil:getDb()
    db:hset("social_bbs_partition_" .. partition_id, "b_delete", 0)
    local bbs_id, err = db:hget("social_bbs_partition_" .. partition_id, "bbs_id")[1]
    local pids, err = db:hget("social_bbs_include_partition", "bbs_id_" .. bbs_id)[1]
    if pids and string.len(pids) > 0 then
        local _pids = Split(pids, ",")
        table.insert(_pids,partition_id);
        local newPids = table.concat(_pids,",");
        db:hset("social_bbs_include_partition", "bbs_id_" .. bbs_id, newPids)
    end
end
------------------------------------------------------------------------------------------------------------------------
---恢复删除.
-- @param #string partition_id
function _M:recoveryPartition(partition_id)
    self:checkParamIsNull({
        partition_id = partition_id
    })
    local row = deleteORRecoveryPartitionToDb(partition_id,0)
    if row > 0 then
        recoveryPartitionToSSDB(partition_id)
    end
end



------------------------------------------------------------------------------------------------------------------------
--通过partition_id获取分区
function _M:getPartitionById(partition_id)
    self:checkParamIsNull({
        partition_id = partition_id
    })
    local sql = "select id,bbs_id,name,sequence,type,type_id from t_social_bbs_partition where id = "..partition_id
    local queryResult = DBUtil:querySingleSql(sql);
    local rr = {}
    if queryResult and #queryResult > 0 then
        rr.partition_id = queryResult[1].id
        rr.bbs_id = queryResult[1].bbs_id
        rr.name = queryResult[1].name
        rr.sequence = queryResult[1].sequence
        rr.type = queryResult[1].type
        rr.type_id = queryResult[1].type_id;
    end
    return rr;
end
return serviceBase:inherit(_M):init()