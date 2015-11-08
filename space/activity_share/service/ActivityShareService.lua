--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/7/13
-- Time: 13:58
-- To change this template use File | Settings | File Templates.
--

local log = require("social.common.log")
local SsdbUtil = require("social.common.ssdbutil")
local TS = require "resty.TS"
local TableUtil = require("social.common.table")
local DBUtil = require "common.DBUtil";
local Constant = require "social.common.constant"
local quote = ngx.quote_sql_str
local _M = {}
--------------------------------------------------------------------
local function checkParamIsNull(t)
    for key, var in pairs(t) do
        if var == nil or string.len(var) == 0 then
            error(key .. " 不能为空.")
        end
    end
end



--------------------------------------------------------------------
-- 获取快乐分享列表
-- {
-- Success:true
-- "pageNumber": 1,
-- "totalPage": 总页数,
-- "totalRow":总记录数,
-- "pageSize":每页条数,
-- list:[{
-- title:标题，
-- view_num:查看次数，
-- reply_num：评论次数.
-- create_date:创建日期
-- id: id
-- },{}]
-- }
local function listFromDb(param)
    local db = DBUtil:getDb()
    local _pagenum = tonumber(param.page_num)
    local _pagesize = tonumber(param.page_size)
    local list_sql = "SELECT id,title,create_date,person_id,person_name FROM T_SOCIAL_ACTIVITY_SHARE WHERE PERSON_ID=%s AND IDENTITY_ID=%s AND MESSAGE_TYPE=%s AND IS_DELETE=0 ORDER BY CREATE_DATE DESC"
    list_sql = string.format(list_sql, param.person_id, param.identity_id, param.message_type)
    local count_sql = "SELECT count(id)  as totalRow  FROM T_SOCIAL_ACTIVITY_SHARE WHERE PERSON_ID=%s AND IDENTITY_ID=%s AND MESSAGE_TYPE=%s AND IS_DELETE=0"
    count_sql = string.format(count_sql, param.person_id, param.identity_id, param.message_type)
    log.debug(count_sql)
    local count = db:query(count_sql);
    log.debug(count)
    if TableUtil:length(count) == 0 then
        return nil;
    end
    log.debug("获取主题帖列表.count:" .. count[1].totalRow);
    local totalRow = count[1].totalRow
    local totalPage = math.floor((totalRow + _pagesize - 1) / _pagesize)
    local offset = _pagesize * _pagenum - _pagesize

    list_sql = list_sql .. " LIMIT " .. offset .. "," .. _pagesize
    log.debug("获取活动列表.list sql:" .. list_sql);
    local list = db:query(list_sql);
    log.debug(list);
    local view_detail_sql = "SELECT R.FILE_ID FROM T_SOCIAL_ACTIVITY_SHARE_DETAIL R WHERE R.SHARE_ID =%s AND R.IS_DELETE = 0 ORDER BY R.SEQ_ID LIMIT 0,1"
    if list then
        local ssdb = SsdbUtil:getDb()
        for i = 1, #list do
            local id = list[i]['id']
            log.debug(id)
            local sql = "SELECT COUNT(*) as _COUNT FROM T_SOCIAL_ACTIVITY_SHARE_ORG WHERE SHARE_ID=%s";
            sql = string.format(sql, id);
            local _ocount = db:query(sql)
            log.debug(_ocount);
            if _ocount and tonumber(_ocount[1]._COUNT) > 0 then
                list[i]['is_shared'] = true;
            else
                list[i]['is_shared'] = false;
            end
            local count = ssdb:get("social_activity_share_view_" .. id .. "_count")
            log.debug(count);
            local view_count = 0
            if count and count[1] and string.len(count[1]) > 0 then
                view_count = tonumber(count[1]);
            end
            view_detail_sql = string.format(view_detail_sql, id);
            local detail_result = db:query(view_detail_sql)
            if detail_result and detail_result[1] then
                list[i]['file_id'] = detail_result[1]['FILE_ID'];
            end
            list[i]['view_count'] = view_count;
        end
    end
    local result = { list = list, totalRow = totalRow, totalPage = totalPage, pageNum = _pagenum, pageSize = _pagesize }
    DBUtil:keepDbAlive(db);
    return result;
end

local function listFromSSDB(param)
end




local function listOrgFromDb(param)
    local _pagenum = tonumber(param.page_num)
    local _pagesize = tonumber(param.page_size)
    local list_sql = "SELECT T1.id,T1.title,T1.create_date,t1.person_id,t1.person_name FROM T_SOCIAL_ACTIVITY_SHARE T1,T_SOCIAL_ACTIVITY_SHARE_ORG T2 WHERE T1.ID = T2.SHARE_ID AND T1.MESSAGE_TYPE=%s AND T2.ORG_ID=%s AND IS_DELETE=0 ORDER BY T1.CREATE_DATE DESC"
    list_sql = string.format(list_sql, param.message_type, param.orgid)
    local count_sql = "SELECT count(id)  as totalRow  FROM T_SOCIAL_ACTIVITY_SHARE T1,T_SOCIAL_ACTIVITY_SHARE_ORG T2 WHERE T1.ID = T2.SHARE_ID  AND T1.MESSAGE_TYPE=%s AND T2.ORG_ID=%s AND IS_DELETE=0"
    count_sql = string.format(count_sql, param.message_type, param.orgid)
    local count = DBUtil:querySingleSql(count_sql);
    if TableUtil:length(count) == 0 then
        return nil;
    end
    log.debug("获取主题帖列表.count:" .. count[1].totalRow);
    local totalRow = count[1].totalRow
    local totalPage = math.floor((totalRow + _pagesize - 1) / _pagesize)
    local offset = _pagesize * _pagenum - _pagesize

    list_sql = list_sql .. " LIMIT " .. offset .. "," .. _pagesize
    log.debug("获取活动列表.list sql:" .. list_sql);
    local list = DBUtil:querySingleSql(list_sql);
    log.debug(list);
    local view_detail_sql = "SELECT R.FILE_ID FROM T_SOCIAL_ACTIVITY_SHARE_DETAIL R WHERE R.SHARE_ID =%s AND R.IS_DELETE = 0 AND R.SEQ_ID=1"
    if list then
        local ssdb = SsdbUtil:getDb()
        for i = 1, #list do
            local id = list[i]['id']
            view_detail_sql = string.format(view_detail_sql, id);
            local detail_result = DBUtil:querySingleSql(view_detail_sql);

            local count = ssdb:get("social_activity_share_view_" .. id .. "_count")
            local view_count = 0
            if count and count[1] and string.len(count[1]) > 0 then
                view_count = tonumber(count[1]);
            end
            log.debug(detail_result)
            list[i]['view_count'] = view_count;
            -- if detail_result and detail_result[1] then
            list[i]['file_id'] = detail_result[1]['FILE_ID'];
            -- end
        end
    end
    local result = { list = list, totalRow = totalRow, totalPage = totalPage, pageNum = _pagenum, pageSize = _pagesize }
    return result;
end

function _M.list(param)
    if param.orgid and string.len(param.orgid) > 0 then
        return listOrgFromDb(param);
    end

    return listFromDb(param)
end


--Title
--Context
--Person_id
--Person_name
--Identity_id
--Message_type
--File_id
--List:[{
--    File_id
--Style
--Seq
--memo
--},{
--
--}]
-----------------------------------------------------------------------------
-- 保存活动
local function saveToDb(param)
    local db = DBUtil:getDb()
    db:query("START TRANSACTION;")
    local insert_sql_z = "insert  into t_social_activity_share (title,context,person_id,person_name,identity_id,message_type,seq_id) values (%s,%s,%s,%s,%s,%s,%s);";
    insert_sql_z = string.format(insert_sql_z, quote(param.title), quote(param.context), quote(param.person_id), quote(param.person_name), quote(param.identity_id), quote(param.message_type), param.seq_id)
    log.debug(insert_sql_z)
    local queryResultZ = db:query(insert_sql_z);
    local share_id;
    -- db:query("COMMIT;");
    log.debug(queryResultZ)
    if queryResultZ then
        share_id = queryResultZ.insert_id;
        local list = param.list;
        local insert_sql = "insert  into t_social_activity_share_detail (file_id,share_id,memo,sequence,style,source,seq_id) values "
        local values_sql = ""
        for i = 1, #list do
            local formatstr = (i == #list and "(%s,%s,%s,%s,%s,%s,%s);") or "(%s,%s,%s,%s,%s,%s,%s),"
            values_sql = values_sql .. string.format(formatstr, quote(list[i].file_id), share_id, quote(list[i].memo), list[i].sequence, quote(list[i].style), quote(list[i].source), list[i].seq_id)
        end
        local sql = insert_sql .. values_sql
        log.debug(sql);
        local r, err, errno, sqlstate = db:query(sql);
        if param.org_ids and string.len(param.org_ids) > 0 then
            local insert_sql_o = "INSERT INTO T_SOCIAL_ACTIVITY_SHARE_ORG (ORG_ID,IDENTITY_ID,SHARE_ID) VALUES "
            local _orgids = Split(param.org_ids, ",")
            local _o_value_sql = "";
            for i = 1, #_orgids do
                local formatstr = (i == #_orgids and "(%s,%s,%s);") or "(%s,%s,%s),"
                _o_value_sql = _o_value_sql .. string.format(formatstr, quote(_orgids[i]), quote(param.identity_id), share_id)
            end
            local _or, err, errno, sqlstate = db:query(insert_sql_o .. _o_value_sql);
            if not _or then
                log.debug("执行ROLLBACK")
                db:query("ROLLBACK;");
                return false
            end
        end

        if not r then
            log.debug("执行ROLLBACK")
            db:query("ROLLBACK;");
            return false
        else
            db:query("COMMIT;");
        end
    else
        db:query("ROLLBACK;");
        return false;
    end
    --local queryResult = DBUtil:querySingleSql(insert_sql .. values_sql);
    DBUtil:keepDbAlive(db);
    return true, share_id
end

local function saveToSSDB(param)
    local key = "social_activity_share_id_" .. param.id;
    local db = SsdbUtil:getDb();
    db:zset("social_activity_share", key, TS.getTs())
    db:multi_hset(key, param);
end

function _M.save(param)
    --  checkParamIsNull(param)
    local result, id = saveToDb(param)
    --    if result then
    --        param.id = id;
    --        saveToSSDB(param);
    --    end
    return result;
end

-----------------------------------------------------------------------------
-- 删除 活动
local function deleteToDb(id)
    log.debug(id);
    local db = DBUtil:getDb()
    db:query("START TRANSACTION;")
    local delete_sql = "UPDATE T_SOCIAL_ACTIVITY_SHARE SET IS_DELETE = 1 WHERE ID = " .. id
    local result = db:query(delete_sql)
    log.debug(result)
    if result.affected_rows > 0 then
        local delete_detail_sql = "UPDATE T_SOCIAL_ACTIVITY_SHARE_DETAIL SET IS_DELETE = 1 WHERE SHARE_ID = " .. id
        local r = db:query(delete_detail_sql)
        log.debug(r);
        if not r then
            db:query("ROLLBACK;");
            return false;
        end
    end
    db:query("COMMIT;")
    DBUtil:keepDbAlive(db);
    return true;
end

local function deleteOrgToDb(org_id, id)
    local db = DBUtil:getDb()
    db:query("START TRANSACTION;")
    local delete_org_sql = "DELETE FROM T_SOCIAL_ACTIVITY_SHARE_ORG WHERE ORG_ID=" .. org_id .. " AND SHARE_ID=" .. id;
    local result_o = db:query(delete_org_sql)
    db:query("COMMIT;")
    DBUtil:keepDbAlive(db);
    if result_o.affected_rows > 0 then
        --        local delete_sql = "UPDATE T_SOCIAL_ACTIVITY_SHARE SET IS_DELETE = 1 WHERE ID = " .. id
        --        local result = db:query(delete_sql)
        --        if result.affected_rows > 0 then
        --            local delete_detail_sql = "UPDATE T_SOCIAL_ACTIVITY_SHARE_DETAIL SET IS_DELETE = 1 WHERE SHARE_ID = " .. id
        --            local r = db:query(delete_detail_sql)
        --            if r then
        --                db:query("COMMIT;")
        --            else
        --                db:query("ROLLBACK;");
        --                return false;
        --            end
        --        else
        --            db:query("ROLLBACK;");
        --            return false;
        --        end
        return true;
    end

    return false;
end

--local function deleteToSSDB(id)
--    local db = SsdbUtil:getDb()
--    local key = "social_activity_share_id_" .. id;
--    db:zdel("social_activity_share", key)
--    db:hclear(key);
--end

function _M.delete(org_id, id)
    --checkParamIsNull({ id = id })
    log.debug(id);
    log.debug(org_id)
    if org_id == nil or string.len(org_id) == 0 then
        return deleteToDb(id);
    else
        return deleteOrgToDb(org_id, id)
    end
end

---------------------------------------------------------------------------------------------------------------
-- 删除活动中的某一个照片.
function _M.deleteDetail(id)
    checkParamIsNull({ id = id })
    local db = DBUtil:getDb()
    local delete_detail_sql = "UPDATE T_SOCIAL_ACTIVITY_SHARE_DETAIL SET IS_DELETE = 1 WHERE SHARE_ID = " .. id
    local r = db:query(delete_detail_sql)
    if r.affected_rows > 0 then
        return true;
    end
    return false;
end


-----------------------------------------------------------------------------
-- 修改活动
-- Id
-- Title
-- Context
-- Person_id
-- Person_name
-- Identity_id
-- Message_type
-- File_id
-- List:[{
-- File_id
-- Style
-- Seq
-- memo
-- },{
--
-- }]
function _M.update(param)
    log.debug("update...")
    local db = DBUtil:getDb()
    db:query("START TRANSACTION;")
    local update_sql = "UPDATE T_SOCIAL_ACTIVITY_SHARE SET TITLE = %s,CONTEXT = %s WHERE ID = %s;";
    update_sql = string.format(update_sql, quote(param.title), quote(param.context), param.id)
    db:query(update_sql) --对主表中的数据进行修改。
    local delete_sql = "DELETE FROM T_SOCIAL_ACTIVITY_SHARE_DETAIL WHERE SHARE_ID = " .. param.id;
    local r1 = db:query(delete_sql) --删除子表中的数据

    local insert_sql = "INSERT INTO T_SOCIAL_ACTIVITY_SHARE_DETAIL (FILE_ID,SHARE_ID,MEMO,SEQUENCE,STYLE,SOURCE,SEQ_ID) VALUES "
    local values_sql = ""
    for i = 1, #param.list do
        local formatstr = (i == #param.list and "(%s,%s,%s,%s,%s,%s,%s);") or "(%s,%s,%s,%s,%s,%s,%s),"
        values_sql = values_sql .. string.format(formatstr, quote(param.list[i].file_id), param.id, quote(param.list[i].memo), param.list[i].sequence, quote(param.list[i].style), quote(param.list[i].source), param.list[i].seq_id)
    end
    local insert_sqls = insert_sql .. values_sql
    log.debug(insert_sqls)
    local r2 = db:query(insert_sqls);
    if r1 and r2 then
        db:query("COMMIT;")
    else
        db:query("ROLLBACK;");
        return false;
    end
    DBUtil:keepDbAlive(db);
    return true;
end

--{
--        title
--context
--id
--list:[
--    {
--        file_id:
--        Memo
--Style
--Create_date
--}
--]
--}

------------------------------------------------------------------------------------
-- 通过id查看 、
function _M.view(id, isadmin)
    local db = SsdbUtil:getDb();
    local view_sql = "SELECT R1.TITLE,R1.CONTEXT,R1.ID,R1.PERSON_ID,R1.PERSON_NAME,R1.CREATE_DATE,R1.SEQ_ID FROM T_SOCIAL_ACTIVITY_SHARE R1 WHERE R1.ID = " .. id
    local view_result = DBUtil:querySingleSql(view_sql);
    local result = { list = {} }
    local view_detail_sql = "SELECT R.FILE_ID,R.MEMO,R.STYLE,R.CREATE_DATE,R.SOURCE,R.ID,R.SEQ_ID FROM T_SOCIAL_ACTIVITY_SHARE_DETAIL R WHERE R.SHARE_ID = " .. id .. " AND R.IS_DELETE = 0"
    if view_result and #view_result > 0 then
        result.id = view_result[1].ID;
        result.context = view_result[1].CONTEXT;
        result.title = view_result[1].TITLE;
        result.person_id = view_result[1].PERSON_ID;
        result.person_name = view_result[1].PERSON_NAME;
        result.create_date = view_result[1].CREATE_DATE;
        result.seq_id = view_result[1].SEQ_ID;
        log.debug(isadmin)
        if not isadmin then
            db:incr("social_activity_share_view_" .. id .. "_count", 1);
        end
        local count = db:get("social_activity_share_view_" .. id .. "_count")
        log.debug(count);
        local view_count = 0
        if count and count[1] and string.len(count[1]) > 0 then
            view_count = tonumber(count[1]);
        end
        result.view_count = view_count;


        local view_detail_result = DBUtil:querySingleSql(view_detail_sql);
        log.debug(view_detail_result)
        if view_detail_result then
            for i = 1, #view_detail_result do
                local temp = {}
                temp.file_id = view_detail_result[i].FILE_ID
                temp.memo = view_detail_result[i].MEMO
                temp.style = view_detail_result[i].STYLE
                temp.create_date = view_detail_result[i].CREATE_DATE
                temp.source = view_detail_result[i].SOURCE
                temp.id = view_detail_result[i].ID
                temp.seq_id = view_detail_result[i].SEQ_ID
                local typeid = "activity_share_comment_" .. result.id .. "_" .. temp.seq_id
                local bbsPostService = require("social.service.BbsPostService")
                temp.reply_count = bbsPostService:postCount(typeid)
                table.insert(result.list, temp);
            end
        end
    end



    return result;
end

------------------------------------------------------------------
-- 通过共享id获取机构列表。
function _M.getOrgListByShareId(shareId)
    checkParamIsNull({
        shereId = shareId
    })
    local sql = "SELECT org_id FROM T_SOCIAL_ACTIVITY_SHARE_ORG WHERE SHARE_ID=%s"
    sql = string.format(sql, shareId);
    local result = DBUtil:querySingleSql(sql);
    return result;
end

------------------------------------------------------------------
-- 修改共享.
function _M.updateShare(identity_id, share_id, org_ids)
    -- log.debug(org_ids[1])
    local db = DBUtil:getDb()
    db:query("START TRANSACTION;")
    local delete_sql = "DELETE FROM T_SOCIAL_ACTIVITY_SHARE_ORG WHERE SHARE_ID=" .. share_id;
    local result_d = db:query(delete_sql);
    log.debug(org_ids);
    if org_ids then
        local insert_sql = "INSERT  INTO T_SOCIAL_ACTIVITY_SHARE_ORG (ORG_ID,IDENTITY_ID,SHARE_ID) VALUES ";
        local values_sql = ""
        for i = 1, #org_ids do
            local formatstr = (i == #org_ids and "(%s,%s,%s);") or "(%s,%s,%s),"
            values_sql = values_sql .. string.format(formatstr, org_ids[i], identity_id, share_id)
        end
        local sql = insert_sql .. values_sql;
        log.debug(sql);
        local result = db:query(sql);
        if result.affected_rows <= 0 then
            db:query("ROLLBACK;");
            return false;
        end
    end
    db:query("COMMIT;")
    return true;
end

return _M;