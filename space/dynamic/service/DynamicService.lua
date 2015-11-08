--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/7/24
-- Time: 9:22
-- To change this template use File | Settings | File Templates.
-- 动态信息service.

local log = require("social.common.log")
local SsdbUtil = require("social.common.ssdbutil")
local TS = require "resty.TS"
local TableUtil = require("social.common.table")
local DBUtil = require "common.DBUtil";
local quote = ngx.quote_sql_str
local util = require("social.common.util")
local _M = {}

------------------------------------------------------------------------------------------------------------------------
-- 通过用户id和用户身份id获取动态信息列表.
-- @param string identity_id
-- @param string paerson_id
-- @param string province_id 省
-- @param string city_id 市
-- @param string area_id 区
-- @param string school_id 校
-- @param string class_id 班.
-- @param string group_id 组
-- @param string message_type 动态消息类型
-- @param string message 信息
-- @param string pi_id person_id+identity_id

--
--local personService = require "base.person.services.PersonService";
--- - local result  = personService:getMyStudents(30317);
---- local result  = personService:getMyColleagues(5,30250);
---- local result  = personService:getMyClassmates(6);
---- local result  = personService:getMyTeachers(6);

local constant = {
    COLLEAGUES = 1, --同事
    CLASSMATES = 2, --同学.
    TEACHERS = 3, --老师
    STUDENTS = 4, --学生
    FRIEND = 5, --朋友.
}
local personid_fill = 10000000
local identityid_fill = 100
local function getPostSphinxData(filter, pagenum, pagesize)
    local offset = pagesize * pagenum - pagesize
    local limit = pagesize
    local str_maxmatches = "10000"
    local db = DBUtil:getDb();
    local sql = "SELECT SQL_NO_CACHE id FROM t_social_dynamic_info_sphinxse WHERE query='%smaxmatches=" .. str_maxmatches .. ";offset=" .. offset .. ";limit=" .. limit .. "';SHOW ENGINE SPHINX  STATUS;"
    sql = string.format(sql, filter);
    log.debug("sql :" .. sql)
    local res = db:query(sql)
    --去第二个结果集中的Status中截取总个数
    local res1 = db:read_result()
    local _, s_str = string.find(res1[1]["Status"], "found: ")
    local e_str = string.find(res1[1]["Status"], ", time:")
    local totalRow = string.sub(res1[1]["Status"], s_str + 1, e_str - 1)
    local totalPage = math.floor((totalRow + pagesize - 1) / pagesize)
    return res, totalRow, totalPage
end

local function getDynamicInfoByIdList(ids, param)
    local ssdb = SsdbUtil:getDb();
    local filterStr = "";
    local message_result = { list = {} }
    if ids then
        local pi_ids = "";
        for i = 1, #ids do
            if i < #ids then
                pi_ids = pi_ids .. tostring(personid_fill + tonumber(ids[i].person_id)) .. tostring(identityid_fill + tonumber(ids[i].identity_id)) .. ","
            else
                pi_ids = pi_ids .. tostring(personid_fill + tonumber(ids[i].person_id)) .. tostring(identityid_fill + tonumber(ids[i].identity_id))
            end
        end
        filterStr = "filter=pi_id," .. pi_ids .. ";";
    end
    local cityFilter = ((param.city_id == nil or string.len(param.city_id) == 0) and "") or "filter=city_id," .. param.city_id .. ";"
    local provinceFilter = ((param.province_id == nil or string.len(param.province_id) == 0) and "") or "filter=province_id," .. param.province_id .. ";"
    local areaFilter = ((param.area_id == nil or string.len(param.area_id) == 0) and "") or "filter=area_id," .. param.area_id .. ";"
    local schoolFilter = ((param.school_id == nil or string.len(param.school_id) == 0) and "") or "filter=school_id," .. param.school_id .. ";"
    local classFilter = ((param.class_id == nil or string.len(param.class_id) == 0) and "") or "filter=class_id," .. param.class_id .. ";"
    local groupFilter = ((param.group_id == nil or string.len(param.group_id) == 0) and "") or "filter=group_id," .. param.group_id .. ";"
    local messageTypeFilter = ((param.message_type == nil or string.len(param.message_type) == 0) and "") or "filter=message_type," .. param.message_type .. ";"
    filterStr = filterStr .. cityFilter .. provinceFilter .. areaFilter .. schoolFilter .. classFilter .. groupFilter .. messageTypeFilter

    local id_result, totalRow, totalPage = getPostSphinxData(filterStr, param.pagenum, param.pagesize);
    message_result.totalRow = totalRow;
    message_result.totalPage = totalPage;
    message_result.pageNumber = param.pagenum;
    message_result.pageSize = param.pagesize;
    local keys = { "identity_id", "person_id", "city_id", "province_id", "area_id", "school_id", "class_id", "group_id", "message_type", "message", "pi_id" }
    log.debug(id_result)
    if id_result and #id_result > 0 then
        for i = 1, #id_result do
            log.debug(id_result[i].id);
            local dynamicInfoResult = ssdb:multi_hget("social_dynamicinfo_id_" .. id_result[i].id, unpack(keys))
            if dynamicInfoResult and #dynamicInfoResult > 0 then
                local _dynamicInfoResult = util:multi_hget(dynamicInfoResult, keys)
                table.insert(message_result.list, _dynamicInfoResult);
            end
        end
    end
    return message_result;
end


function _M.getDynamicInfoList(param)
    --查询好友接口
    --查询出person_id+identity_id
    --person_id+identity_id 去sphinx查询dynamic表中查询message

    local personService = require "base.person.services.PersonService";
    local id_obj = {}
    if param.type == constant.COLLEAGUES then --同事
        local result = personService:getMyColleagues(param.identity_id, param.person_id);
        if result.teacher_list then
            for i = 1, #result.teacher_list do
                local _t = {}
                _t.identity_id = param.identity_id;
                _t.person_id = result.teacher_list[i].person_id;
                table.insert(id_obj, _t);
            end
        end
    elseif param.type == constant.CLASSMATES then --同学
        local result = personService:getMyClassmates(param.person_id);
        local id_obj = {}
        if result.student_list then
            for i = 1, #result.student_list do
                local _t = {}
                _t.identity_id = param.identity_id;
                _t.person_id = result.student_list[i].student_id;
                table.insert(id_obj, _t);
            end
        end
    elseif param.type == constant.TEACHERS then --老师
        local result = personService:getMyTeachers(param.person_id);
        local id_obj = {}
        if result.teacher_list then
            for i = 1, #result.teacher_list do
                local _t = {}
                _t.identity_id = param.identity_id;
                _t.person_id = result.teacher_list[i].teacher_id;
                table.insert(id_obj, _t);
            end
        end
    elseif param.type == constant.STUDENTS then --学生
        local result = personService:getMyStudents(param.person_id);
        if result.student_list then
            for i = 1, #result.student_list do
                local _t = {}
                _t.identity_id = param.identity_id;
                _t.person_id = result.student_list[i].student_id;
                table.insert(id_obj, _t);
            end
        end
    elseif param.type == constant.FRIEND then --好友
        local friendService = require "space.services.FriendService";
        local ids = friendService:getFriendsByPersonIdAndIdentityId(param.person_id, param.identity_id)
        log.debug(ids)
    else
        id_obj = nil
    end
    local message_result = getDynamicInfoByIdList(id_obj, param)
    return message_result;
end


------------------------------------------------------------------------------------------------------------------------
-- 保存动态信息.
function _M.saveDynamicInfo(param)
    --- 补位操作.
    local p = personid_fill + param.person_id
    log.debug("p:" .. p);
    local i = identityid_fill + param.identity_id;
    log.debug("i:" .. i);
    local pi_id = tonumber(tostring(p) .. tostring(i));
    log.debug(pi_id)
    --- 拼sql.
    local column = "INSERT INTO T_SOCIAL_DYNAMIC_INFO(IDENTITY_ID,PERSON_ID,CITY_ID,PROVINCE_ID,AREA_ID,SCHOOL_ID,CLASS_ID,GROUP_ID,MESSAGE_TYPE,PI_ID,MESSAGE,TS) VALUES"
    local values = "(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
    values = string.format(values, param.identity_id, param.person_id, param.city_id, param.province_id, param.area_id, param.school_id, param.class_id, param.group_id, param.message_type, pi_id, quote(param.message), TS.getTs())
    log.debug(column .. values)
    local result = DBUtil:querySingleSql(column .. values);
    if result then
        local ssdb = SsdbUtil:getDb()
        ssdb:multi_hset("social_dynamicinfo_id_" .. result.insert_id, param)
    end
    return result;
end

return _M;