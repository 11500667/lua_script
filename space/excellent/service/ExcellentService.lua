--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/28
-- Time: 16:21
-- To change this template use File | Settings | File Templates.
--
local DBUtil = require "common.DBUtil";
local SsdbUtil = require("social.common.ssdbutil")
local cjson = require "cjson"
local log = require("social.common.log")
--
--管理者空间获取优秀教师
--通过多个机构id与机构type获取多个
--效仿http://10.10.6.199/dsideal_yy/space/getSpacePortlet?random_num=2232793&org_id=300529&identity_id=103&type=3&limit=12
-- 1省2市3区县4校5分校6部门7班级
local _M = {}
--SELECT t.* FROM t_social_space_excellence t WHERE (t.org_id =300529 AND t.identityid=3) OR (t.org_id =30164 AND t.identityid=3)

--拼装or语句
--@param org_ids table
--@param identity_ids table
local function splitOrStr(org_ids, org_types, identity_id)
    local orStr = "";
    for i = 1, #org_ids do
        orStr = orStr .. "(T.ORG_ID=" .. org_ids[i] .. " AND T.ORG_TYPE=" .. org_types[i] .. " AND T.IDENTITYID=" .. identity_id .. ")";
        if i < #org_ids then
            orStr = orStr .. " OR "
        end
    end
    return orStr;
end


local function localSchoolList(ids, org_types, logo_urls)

    local schoolService = require "base.org.services.SchoolService";
    local util = require "space.util.util";

    local schoolPageList = schoolService:getSchoolByIds(ids);
    ngx.log(ngx.ERR, "cjson out=============>", cjson.encode(schoolPageList))
    util:logData(ids)
    local result = {}
    if schoolPageList then
        for i = 1, #schoolPageList do
            local restemp = {}
            restemp.name = schoolPageList[i].school_name
            restemp.id = schoolPageList[i].school_id
            restemp.org_type = org_types[i]
            restemp.stage_name = schoolPageList[i].stage_name
            --ngx.log(ngx.ERR,"ids===================================>schoolPageList[i].school_id::::",schoolPageList[i].school_id)
            restemp.logo_file_id = ""
            for j = 1, #ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                if schoolPageList[i].school_id == ids[j] then
                    --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id = logo_urls[j]
                    break;
                end
            end
            table.insert(result, restemp)
        end
    end
    return result;
end

local function localClassList(ids, org_types, logo_urls)

    local classService = require "base.org.services.ClassService";
    local classPageList = classService:getClassByIds(ids);
    local result = {}
    if classPageList then
        for i = 1, #classPageList do
            local restemp = {}
            restemp.name = classPageList[i].class_name
            restemp.id = classPageList[i].class_id
            restemp.org_type = org_types[i]
            restemp.school_name = classPageList[i].school_name
            restemp.logo_file_id = ""
            for j = 1, #ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                if classPageList[i].class_id == ids[j] then
                    --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id = logo_urls[j]
                    break;
                end
            end
            table.insert(result, restemp)
        end
    end
    return result;
end

local function localTeacherList(ids, org_types, logo_urls)
    log.debug(ids)
    local personService = require "base.person.services.PersonService";

    local personPageList = personService:getPersonByIds(ids);
    log.debug(personPageList)
    local result = {}
    if personPageList then
        for i = 1, #personPageList do
            local restemp = {}
            restemp.name = personPageList[i].person_name
            restemp.id = personPageList[i].person_id
            restemp.org_type = org_types[i]
            for j = 1, #ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                if personPageList[i].person_id == ids[j] then
                    --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id = logo_urls[j]
                    break;
                end
            end
            table.insert(result, restemp)
        end
    end
    return result
end

local function localStudentList(ids, org_types, logo_urls)
    local studentService = require "base.student.services.StudentService";
    local studentPageList = studentService:getStudentByIds(ids);
    local result = {}
    if studentPageList then
        for i = 1, #studentPageList do
            local restemp = {}
            restemp.name = studentPageList[i].student_name
            restemp.id = studentPageList[i].student_id
            restemp.org_type = org_types[i]
            for j = 1, #ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                if studentPageList[i].student_id == ids[j] then
                    --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id = logo_urls[j]
                    break;
                end
            end
            table.insert(result, restemp)
        end
    end
    return result;
end

function _M.getExcellence(org_ids, org_types, identity_id, limit)

    log.debug(org_ids);
    local resResult = { list = {} }
    local orStr = splitOrStr(org_ids, org_types, identity_id);
    local querySql = "select t.record_id,t.org_type from t_social_space_excellence  t where 1=1 AND " .. orStr .. " limit " .. limit
    local queryCountSql = "select count(*) total_row from t_social_space_excellence  t where 1=1 AND " .. orStr
    local db = DBUtil:getDb()
    log.debug(querySql)
    local queryResult, err = db:query(querySql)
    if not queryResult then
        error()
    end
    local queryCountResult, err = db:query(queryCountSql);
    log.debug(queryCountResult)
    if queryResult then

        local table_ids = {}
        local logo_urls = {}
        local _org_types = {}
        for i = 1, #queryResult do
            local restemp = {}
            local info_key = ""
            local logo_url = ""
            if identity_id == 1 then
                info_key = "space_ajson_orgbaseinfo_" .. queryResult[i]["record_id"] .. "_104";
            elseif identity_id == 2 then
                info_key = "space_ajson_orgbaseinfo_" .. queryResult[i]["record_id"] .. "_105";
            elseif identity_id == 3 then
                info_key = "space_ajson_personbaseinfo_" .. queryResult[i]["record_id"] .. "_5";
            elseif identity_id == 4 then
                info_key = "space_ajson_personbaseinfo_" .. queryResult[i]["record_id"] .. "_6";
            end
            local ssdb = SsdbUtil:getDb()
            log.debug(info_key)
            local logoResult = ssdb:get(info_key)
            log.debug(logoResult)
            if logoResult and logoResult[1] and string.len(logoResult[1]) > 0 then
                local jsonObj = cjson.decode(logoResult[1])
                if identity_id == 1 then
                    logo_url = jsonObj.org_logo_fileid
                elseif identity_id == 2 then
                    logo_url = jsonObj.org_logo_fileid
                elseif identity_id == 3 then
                    logo_url = jsonObj.space_avatar_fileid
                elseif identity_id == 4 then
                    logo_url = jsonObj.space_avatar_fileid
                end
            end
            log.debug(queryResult[i]["record_id"]);
            table.insert(table_ids, queryResult[i]["record_id"])
            table.insert(_org_types, queryResult[i]["org_type"])
            table.insert(logo_urls, logo_url)
        end
        if table_ids and #table_ids > 0 then
            log.debug(identity_id)
            if identity_id == 1 then
                resResult.list = localSchoolList(table_ids, _org_types, logo_urls)
            elseif identity_id == 2 then
                resResult.list = localClassList(table_ids, _org_types, logo_urls)
            elseif identity_id == 3 then
                log.debug("准备调用老师获取老师的基本信息.")
                resResult.list = localTeacherList(table_ids, _org_types, logo_urls)
            elseif identity_id == 4 then
                resResult.list = localStudentList(table_ids, _org_types, logo_urls)
            end
            log.debug(resResult);
        end
    end
    resResult['total_row'] = queryCountResult[1].total_row;
    log.debug(resResult);
    return resResult;
end



return _M;

