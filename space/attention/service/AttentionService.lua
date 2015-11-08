--
-- Created by IntelliJ IDEA.
-- User: 张海 .
-- Date: 2015/7/6
-- Time: 9:46
-- To change this template use File | Settings | File Templates.
--

local log = require("social.common.log")
local RedisUtil = require("social.common.redisutil")
local SsdbUtil = require("social.common.ssdbutil")
local TS = require "resty.TS"
local _M = {}

--------------------------------------------------------------------
local function checkParamIsNull(t)
    for key, var in pairs(t) do
        if var == nil or string.len(var) == 0 then
            error(key .. " 不能为空.")
        end
    end
end

--设置关注
local function setAttention(param)
    local db = SsdbUtil:getDb();
    local key = param.b_identityid .. "_" .. param.b_personid
    db:zset("space_attention_identityid_" .. param.identityid .. "_personid_" .. param.personid, key, TS.getTs())
    db:incr("space_attention_identityid_" .. param.identityid .. "_personid_" .. param.personid .. "_count", 1);
end

--设置被关注.
local function setBAttention(param)
    local db = SsdbUtil:getDb();
    local key = param.identityid .. "_" .. param.personid
    db:zset("space_b_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid, key, TS.getTs())
    db:incr("space_b_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid .. "_count", 1);
end

-------------------------------------------------------------
-- 保存关注人信息.
function _M.save(param)
    checkParamIsNull(param)
    local status = pcall(function()
        setAttention(param)
        setBAttention(param)
    end)
    if status then
        return true;
    end
    return false;
end

local function getPersonInfoByRedis(zResult)
    local aService = require "space.services.PersonAndOrgBaseInfoService"
    local id_result = {}
    if zResult and zResult[1] and zResult[1] ~= "ok" then
        for i = 1, #zResult, 2 do
            local temp = {}
            local r = Split(zResult[i], "_")
            while true do
                if r[1] == "" or r[2] == "" then
                    break;
                end
                temp.person_id = r[2];
                temp.identity_id = r[1];
                table.insert(id_result, temp);
                break;
            end
        end
        local rt = aService:getPersonBaseInfoByPersonIdAndIdentityId(id_result)
        return rt;
    end
    return {};
end


local function getCount(key, pagesize, pagenum)
    local db = SsdbUtil:getDb();
    local t_totalRow = db:zcount(key, "", "")
    local totalRow = t_totalRow[1]
    local totalPage = math.floor((totalRow + pagesize - 1) / pagesize)
    if pagenum > totalPage then
        pagenum = totalPage
    end
    local offset = pagesize * pagenum - pagesize
    local limit = pagesize
    return offset, limit, totalRow, totalPage
end

local function getAttention(personid, identityid, pagesize, pagenum)
    local db = SsdbUtil:getDb();
    local offset, limit, totalRow, totalPage = getCount("space_attention_identityid_" .. identityid .. "_personid_" .. personid, pagesize, pagenum)
    log.debug("identityid:" .. identityid)
    log.debug("personid:" .. personid)
    local key = "space_attention_identityid_" .. identityid .. "_personid_" .. personid;
    log.debug("key:" .. key)
    local zResult = db:zrange(key, offset, limit)
    log.debug(zResult);
    local result = getPersonInfoByRedis(zResult)
    return result, totalRow, totalPage;
end

local function getBAttention(personid, identityid, pagesize, pagenum)
    local db = SsdbUtil:getDb();
    local name = "space_b_attention_identityid_" .. identityid .. "_personid_" .. personid;
    log.debug(name)
    local offset, limit, totalRow, totalPage = getCount(name, pagesize, pagenum)
    local zResult = db:zrange(name, offset, limit)
    log.debug(name)
    log.debug(zResult);
    local result = getPersonInfoByRedis(zResult)
    local key = identityid .. "_" .. personid
    for i = 1, #result do
        local _identity_id = result[i]['identity_id']
        local _person_id = result[i]['personId']
        log.debug("identity_id:" .. _identity_id);
        log.debug("person_id:" .. _person_id);
        --        log.debug("key :" .. key);
        local _exists1, err = SsdbUtil:getDb():zexists("space_attention_identityid_" .. _identity_id .. "_personid_" .. _person_id, key);
        local _exists2, err = SsdbUtil:getDb():zexists("space_attention_identityid_" .. identityid .. "_personid_" .. personid, _identity_id .. "_" .. _person_id);
        log.debug(_exists1)
        log.debug(_exists2)
        if _exists1[1] == "1" and _exists2[1] == "1" then
            result[i].each_other = true;
        else
            result[i].each_other = false;
        end
    end
    return result, totalRow, totalPage;
end

--------------------------------------------------------------
-- 查询关注人
function _M.queryAttention(param)
    log.debug(param.personid)
    checkParamIsNull({
        personid = param.personid,
        identityid = param.identityid,
        --        b_personid = param.b_personid,
        --        b_identityid = param.b_identityid,
    })
    local result, totalRow, totalPage = getAttention(param.personid, param.identityid, param.page_size, param.page_num)
    log.debug(result)
    return result, totalRow, totalPage
end

--------------------------------------------------------------
-- 查询关注人
function _M.queryBAttention(param)
    log.debug(param)
    checkParamIsNull({
        personid = param.personid,
        identityid = param.identityid,
        --        b_personid = param.b_personid,
        --        b_identityid = param.b_identityid,
    })
    local result, totalRow, totalPage = getBAttention(param.personid, param.identityid, param.page_size, param.page_num)
    return result, totalRow, totalPage
end


function _M.get(param)
    local result = {}
    --    checkParamIsNull({
    --        personid = personid,
    --        identityid = identityid,
    --    })
    log.debug(param)
    local db = SsdbUtil:getDb();
    if param.personid and param.identityid and string.len(param.personid) > 0 and string.len(param.identityid) > 0 then

        --是否关注
        local is_attention = db:zexists("space_attention_identityid_" .. param.identityid .. "_personid_" .. param.personid, param.b_identityid .. "_" .. param.b_personid)
        log.debug(is_attention)
        if is_attention and is_attention[1] and tonumber(is_attention[1]) > 0 then
            result.is_attention = 1;
        else
            result.is_attention = 0;
        end
        --被谁访问
        db:zset("space_attention_access_" .. param.type .. "_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid, param.identityid .. "_" .. param.personid, TS.getTs())
        db:zset("space_attention_b_access_" .. param.type .. "_identityid_" .. param.identityid .. "_personid_" .. param.personid, param.b_identityid .. "_" .. param.b_personid, TS.getTs())
    end

    --关注量
    local attention_count = db:get("space_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid .. "_count"); --关注数量
    if attention_count and attention_count[1] and string.len(attention_count[1]) > 0 then
        result.attention_count = attention_count[1];
    else
        result.attention_count = 0
    end
    --被关注量
    local attentionb_count = db:get("space_b_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid .. "_count"); --被关注数量
    if attentionb_count and attentionb_count[1] and string.len(attentionb_count[1]) > 0 then
        result.attentionb_count = attentionb_count[1];
    else
        result.attentionb_count = 0
    end

    local access_quantity = db:get("space_attention_access_" .. param.type .. "_quantity_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid)
    if access_quantity and access_quantity[1] and string.len(access_quantity[1]) > 0 then
        result.access_quantity = access_quantity[1]
    else
        result.access_quantity = 0
    end
    db:incr("space_attention_access_" .. param.type .. "_quantity_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid, 1); --访问量加1



    return result;
end

function _M.access(personid, identityid, b_personid, b_identityid, type)
    local db = SsdbUtil:getDb();
    if not personid and not identityid then
        local key = identityid .. "_" .. personid
        db:zset("space_attention_access_" .. type .. "_identityid_" .. b_identityid .. "_personid_" .. b_personid, key, TS.getTs())
    end
    local result = db:incr("space_attention_access_" .. type .. "_quantity_identityid_" .. b_identityid .. "_personid_" .. b_personid, 1);
    return result;
end

function _M.accesslist(personid, identityid, type, pagesize, pagenum)
    local db = SsdbUtil:getDb();
    local name = "space_attention_access_" .. type .. "_identityid_" .. identityid .. "_personid_" .. personid;
    log.debug(name)
    local offset, limit, totalRow, totalPage = getCount(name, pagesize, pagenum)
    local zResult = db:zrange(name, offset, limit)
    log.debug(zResult)
    local result = getPersonInfoByRedis(zResult)
    return result, totalRow, totalPage;
end

function _M.accesslist_b(personid, identityid, type, pagesize, pagenum)
    local db = SsdbUtil:getDb();
    local name = "space_attention_b_access_" .. type .. "_identityid_" .. identityid .. "_personid_" .. personid
    log.debug(name)
    local offset, limit, totalRow, totalPage = getCount(name, pagesize, pagenum)
    local zResult = db:zrange(name, offset, limit)
    local result = getPersonInfoByRedis(zResult)

    return result, totalRow, totalPage;
end

function _M.delete(param)
    checkParamIsNull(param)
    local db = SsdbUtil:getDb();
    local key = param.b_identityid .. "_" .. param.b_personid
    db:zdel("space_attention_identityid_" .. param.identityid .. "_personid_" .. param.personid, key)
    local num = db:incr("space_attention_identityid_" .. param.identityid .. "_personid_" .. param.personid .. "_count", -1);
    if num and num[1] then
        if tonumber(num[1]) <= 0 then
            db:set("space_attention_identityid_" .. param.identityid .. "_personid_" .. param.personid .. "_count", 0)
        end
    end
    local b_key = param.identityid .. "_" .. param.personid
    db:zdel("space_b_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid, b_key)
    local num_b = db:incr("space_b_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid .. "_count", -1);
    if num_b and num_b[1] then
        if tonumber(num_b[1]) <= 0 then
            db:set("space_b_attention_identityid_" .. param.b_identityid .. "_personid_" .. param.b_personid .. "_count", 0)
        end
    end
    log.debug(num)
    log.debug(num_b)
    return true;
end

return _M;
