--
--    张海  2015-05-06
--    描述：  BBS service 接口.
--
local util = require("social.common.util")
local DBUtil = require "common.DBUtil";
local TableUtil = require("social.common.table")
local SsdbUtil = require("social.common.ssdbutil")
local date = require("social.common.date");
local log = require("social.common.log")
local BbsService = {}


--------------------------------------------------------------------------------
-- 通过id获取bbs信息
-- @param #string bbsid
-- @result #table result bbs信息
function BbsService:getBbsByIdFromDb(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbs id 不能为空.")
    end
    local sql = string.format("SELECT * FROM T_SOCIAL_BBS WHERE ID=%s", bbsid);
    local result = DBUtil:querySingleSql(sql);
    return result
end


--------------------------------------------------------------------------------
-- 通过bbsid获取未删除的区.
-- @param string bbsid .
-- @return table 查询的bbs分区列表.
function BbsService:getPartitions(bbsid)
    local sql = "SELECT * FROM T_SOCIAL_BBS_PARTITION T WHERE T.BBS_ID=" .. bbsid .. " AND T.B_DELETE=0 ORDER BY T.SEQUENCE";
    log.debug("通过论坛id查询分区表sql:" .. sql);
    local queryResult = DBUtil:querySingleSql(sql);
    return queryResult;
end


--------------------------------------------------------------------------------
-- 通过bbsid与partitionid获取未删除的版块列表.
-- @param #string bbsid
-- @param #string partitionid.
function BbsService:getForums(bbsid, partitionid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid 不能为空.")
    end
    if partitionid == nil or string.len(partitionid) == 0 then
        error("partitionid 不能为空.")
    end
    local sql = string.format("SELECT * FROM T_SOCIAL_BBS_FORUM T WHERE T.BBS_ID=%s AND T.PARTITION_ID=%s AND T.B_DELETE=0 ORDER BY T.SEQUENCE", bbsid, partitionid);
    log.debug("通过bbsid与partitionid获取版块列表sql:" .. sql);

    local queryResult = DBUtil:querySingleSql(sql);
    return queryResult;
end

--------------------------------------------------------------------------------
-- 对模块下的帖数个数进行修改.
--
function BbsService:updateForumTopicPostNumber(forumid)
    --    if forumid==nil or string.len(forumid)==0 then
    --        error("forumid 不能为空.")
    --    end
    --     local db = DBUtil:getDb()
    --    local selectLastpostTimeSql = "SELECT (NOW()-T.LAST_POST_TIME) V FROM T_SOCIAL_BBS_FORUM T WHERE'"..forumid.."'"
    --    local result = db.query(selectLastpostTimeSql);
    --    if result then
    --         local r = tonumber(result[1]["V"])
    --         if r<=0 then
    --             "UPDATE T_SOCIAL_BBS_FORUM SET POST_TODAY=POST_TODAY+1 WHERE ID='"..forumid.."'"
    --         else
    --
    --         end
    --    end
    --
    --    local todaySql = "UPDATE T_SOCIAL_BBS_FORUM SET POST_TODAY=POST_TODAY+1 WHERE ID='"..forumid.."'"
    --
end

--------------------------------------------------------------------------------
-- 通过fourmid获取fourm.
-- @param #string fourmid
function BbsService:getForumById(fourmid)
    if fourmid == nil or string.len(fourmid) == 0 then
        error("fourmid 不能为空.")
    end
    local sql = string.format("SELECT T.ID,T.BBS_ID,T.PARTITION_ID,T.NAME,T.ICON_URL,T.DESCRIPTION,T.SEQUENCE,T.B_DELETE,T.PID,T.POST_TODAY,T.POST_YESTODAY,T.TOTAL_TOPIC FROM T_SOCIAL_BBS_FORUM T WHERE T.ID=%s", fourmid);
    log.debug("通过fourmid获取版块列表sql:" .. sql);
    local queryResult = DBUtil:querySingleSql(sql);
    return queryResult;
end

--------------------------------------------------------------------------------
-- 通过personid ,froumid,identityid获取用户与板块关系
-- @param #string fourmid
-- @param #string fourmid
-- @param #string identityId
function BbsService:getForumnUserByPersonId(personId, forumId, identityId)
    if personId == nil or string.len(personId) == 0 then
        error("personId 不能为空.")
    end
    if forumId == nil or string.len(forumId) == 0 then
        error("forumId 不能为空.")
    end

    if identityId == nil or string.len(identityId) == 0 then
        error("identityId 不能为空.")
    end
    local sql = "SELECT * FROM T_SOCIAL_BBS_FORUM_USER WHERE PERSON_ID=%s and FORUM_ID=%s and IDENTITY_ID=%s";
    log.debug("getForumnUserByPersonId sql:" .. sql);
    sql = string.format(sql, personId, forumId, identityId)
    local queryResult = DBUtil:querySingleSql(sql);
    return queryResult;
end

--------------------------------------------------------------------------------
-- 通过fourmid获取fourm.
-- @param #string fourmid
function BbsService:getForumByIdFromSsdb(fourmid)
    if fourmid == nil or string.len(fourmid) == 0 then
        error("fourmid 不能为空.")
    end
    local keys = { "id", "name", "icon_url", "last_post_time", "total_topic", "total_topic_post", "description", "forum_admin_list" }
    local db = SsdbUtil:getDb();
    local fourm = db:multi_hget("social_bbs_forum_" .. fourmid, unpack(keys))
    util:log_r_keys("social_bbs_forum_" .. fourmid, "multi_hget")
    local _fourm = {}
    if fourm and #fourm > 0 then
        _fourm = util:multi_hget(fourm, keys)
    end
    return _fourm;
end

----------------------------------------------------------------------------------
----- 获取版主信息.
---- @param #string forumid
-- function BbsService:getForumAdminList(forumid)
-- local db = SsdbUtil:getDb();
-- local forumAdminStrA = db:hget("social_bbs_forum_"..forumid,"forum_admin_list")
-- local forumAdminList = "";
-- if forumAdminStrA and forumAdminStrA[1] and string.len(forumAdminStrA[1]) > 0 then
-- forumAdminList = tostring(forumAdminStrA[1]);
-- end
-- return forumAdminList;
-- end


--------------------------------------------------------------------------------
-- 通过userid获取user

--------------------------------------------------------------------------------
-- 通过forumid,personid,identityid,personname,flag保存用户与版块关系.
-- @param #string forumid
-- @param #string personid
-- @param #string identityid
-- @param #string personname
-- @param #string flag
function BbsService:saveForumUser(forumid, personid, identityid, personname, flag)
    local result = {}
    if forumid and string.len(forumid) > 0 and personid and string.len(personid) > 0 and identityid and string.len(identityid) > 0 then
        forumid = tonumber(forumid);
        personid = tonumber(personid);
        identityid = tonumber(identityid);
        flag = tonumber(flag);
        local sql = string.format("INSERT INTO `T_SOCIAL_BBS_FORUM_USER` (`FORUM_ID`, `PERSON_ID`, `IDENTITY_ID`, `PERSON_NAME`, `FLAG`) VALUES (%d, %d, %d, %s, %d)", forumid, personid, identityid, ngx.quote_sql_str(personname), flag);
        log.debug("保存版块用户关系表sql:" .. sql);
        result = DBUtil:querySingleSql(sql);
    end
    return result;
end

--------------------------------------------------------------------------------
-- 验证用户是否可以在此bbs发贴
-- @param #string personid.
-- @param #string identityid.
-- @param #string bbsid.
function BbsService:checkForumUser(personid, identityid, bbsid)
    --- 通过用户personid获取用户
    -- 去基础信息中通过personid获取用户机构（省市区校）id.
    -- 获取province_id,city_id,area_id,school_id
    --
    local PersonInfoModel = require("base.person.model.PersonInfoModel");
    local bbsResult = self:getBbsByIdFromDb(bbsid)
    log.debug("查询 bbs 完成")
    if bbsResult then
        local bbs = bbsResult[1]
        local regionid = bbs["region_id"]
        --判断是否存在与province_id,city_id,area_id,school_id之中
        log.debug("调用基础信息接口开始.")
        local ids = PersonInfoModel:getPersonDetail(personid, identityid)
        log.debug(ids)
        log.debug("调用基础信息接口结束.")
        if ids then
            if ids.province_id == tostring(regionid) or ids.city_id == tostring(regionid) or ids.district_id == tostring(regionid) or ids.school_id == tostring(regionid) then
                return true
            end
        end
    end
    return false
end

---------------------------------------------------------------------------------
local db = {}
local function getFourmById(bbsid, fid)
    local keys = { "id", "name", "icon_url", "last_post_time", "total_topic", "total_topic_post" }
    local db = SsdbUtil:getDb()
    local fourm = db:multi_hget("social_bbs_forum_" .. fid, unpack(keys))
    util:log_r_keys("social_bbs_forum_" .. fid, "multi_hget")
    local _fourm = {}
    if fourm and #fourm > 0 then
        _fourm = util:multi_hget(fourm, keys)
        local service = require("social.service.BbsTotalService")
        _fourm.total_topic = service:getForumTopicHistoryNumber(bbsid, fid) --此版块主题帖数(包括历史)
        local postnumb = service:getForumPostHistoryNum(bbsid, fid)
        _fourm.total_topic_post = postnumb --回复帖数(包括历史)
    end

    return _fourm;
end

------------------------------------------------------------------------------
-- 通过区域id获取bbs基础信息，不带版块信息与区信息.
-- @param #string regionId
function BbsService:getBbsInfoByRegionId(regionId)
    if regionId == nil or string.len(regionId) == 0 then
        error("regionId不能为空.")
    end
    local db = SsdbUtil:getDb()
    local rbbsid, err = db:hget("social_bbs_region_" .. regionId, "bbs_id")

    if rbbsid and rbbsid[1] and string.len(rbbsid[1]) > 0 then
        local bbsid = rbbsid[1];
        local keys = { "id", "name", "logo_url", "icon_url", "domain" }
        local bbsResult = db:multi_hget("social_bbs_" .. bbsid, unpack(keys))
        return bbsResult
    else
        return nil;
    end
end

------------------------------------------------------------------------------
-- 通过bbsid获取bbs信息.
-- @param #string bbsid
function BbsService:getBbsInfoByBbsId(bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbsid不能为空.")
    end
    local db = SsdbUtil:getDb()
    local keys = { "id", "name", "logo_url", "icon_url", "domain", "region_id", "region_type" }
    local bbsResult = db:multi_hget("social_bbs_" .. bbsid, unpack(keys))
    return bbsResult
end


------------------------------------------------------------------------------
-- 通过bbsid获取区信息，版块信息.(通过ssdb获取)
-- @param #string bbsid
-- @return #table bbs信息首页.
function BbsService:getBbsById(bbsid)
    log.debug("getBbsById bbsid =" .. bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbs id 不能为空.")
    end
    local db = SsdbUtil:getDb()
    local keys = { "id", "total_today", "total_yestoday", "total", "name", "logo_url", "icon_url", "domain", "region_id", "region_type" }
    local bbsResult = db:multi_hget("social_bbs_" .. bbsid, unpack(keys))
    util:log_r_keys("social_bbs_" .. bbsid, "multi_hget")
    --    for _, var in pairs(bbsResult) do
    --        log.debug(var)
    --    end
    local bbs = {}
    if bbsResult and #bbsResult > 0 then
        bbs = util:multi_hget(bbsResult, keys) --工具实现对multi_hget解析
        local totalService = require("social.service.BbsTotalService")
        bbs.total_today = totalService:getCurrentDatePostTotal(bbsid)
        bbs.total_yestoday = totalService:getYestoryPostTotal(bbsid)
        bbs.total = totalService:getHistoryPostTotal(bbsid);
        bbs.partition_list = {}
    else
        return nil
    end
    local SOCIAL_BBS_INCLUDE_PARTITION = "social_bbs_include_partition";
    local partitionResult = db:hget(SOCIAL_BBS_INCLUDE_PARTITION, "bbs_id_" .. bbsid)
    util:log_r_keys(SOCIAL_BBS_INCLUDE_PARTITION, "hget")
    log.debug("getBbsById :")
    log.debug(partitionResult)
    if partitionResult and string.len(partitionResult[1]) > 0 then
        local pidstr = partitionResult[1]
        --util:logData("pids 集合:" .. pidstr);
        local pids = Split(pidstr, ",")
        --util:logData(pids);
        for _, pid in ipairs(pids) do
            if string.len(pid) > 0 then
                local partition = db:multi_hget("social_bbs_partition_" .. pid, "id", "bbs_id", "name", "sequence")
                util:log_r_keys("social_bbs_partition_" .. pid, "multi_hget")
                --util:logData("获取分区信息:");
                --util:logData(partition);
                local _partition = {}
                if partition and #partition > 0 then
                    --util:logData(partition);
                    _partition.id = partition[2];
                    _partition.bbs_id = partition[4];
                    _partition.name = partition[6];
                    _partition.sequence = partition[8];
                    _partition.forum_list = {}
                    local SOCIAL_BBS_INCLUDE_FORUM = "social_bbs_include_forum";
                    --util:logData("partition[2]:");
                    --util:logData(partition[2]);
                    local forumResult = db:hget(SOCIAL_BBS_INCLUDE_FORUM, "partition_id_" .. partition[2])
                    util:log_r_keys("social_bbs_include_forum", "hget")
                    if forumResult and string.len(forumResult[1]) > 0 then
                        local fidstr = forumResult[1]
                        local fids = Split(fidstr, ",")
                        log.debug("=============fids 集合:");
                        log.debug(fids);
                        for _, fid in ipairs(fids) do
                            if string.len(fid) > 0 then
                                local _fourm = getFourmById(bbsid, fid)
                                table.insert(_partition.forum_list, _fourm)
                            end
                        end
                    end
                end
                table.insert(bbs.partition_list, _partition)
            end
        end
    else
        bbs.partition_list = {}
    end
    return bbs;
end

------------------------------------------------------------------------------
-- 通过bbsid获取所有版块id(通过ssdb获取,未删除的)
-- @param #string bbsid
-- @return #table bbs信息首页.
function BbsService:getForumIdsById(bbsid)
    log.debug("getBbsById bbsid =" .. bbsid)
    if bbsid == nil or string.len(bbsid) == 0 then
        error("bbs id 不能为空.")
    end
    local forumIds = {}
    local db = SsdbUtil:getDb()
    local SOCIAL_BBS_INCLUDE_PARTITION = "social_bbs_include_partition";
    local partitionResult = db:hget(SOCIAL_BBS_INCLUDE_PARTITION, "bbs_id_" .. bbsid)
    if partitionResult and string.len(partitionResult[1]) > 0 then
        local pidstr = partitionResult[1]
        local pids = Split(pidstr, ",")
        for _, pid in ipairs(pids) do
            if string.len(pid) > 0 then
                local partition = db:multi_hget("social_bbs_partition_" .. pid, "id")
                local _partition = {}
                if partition and #partition > 0 then
                    _partition.id = partition[2];
                    local SOCIAL_BBS_INCLUDE_FORUM = "social_bbs_include_forum";
                    local forumResult = db:hget(SOCIAL_BBS_INCLUDE_FORUM, "partition_id_" .. partition[2])
                    if forumResult and string.len(forumResult[1]) > 0 then
                        local fidstr = forumResult[1]
                        local fids = Split(fidstr, ",")
                        log.debug("=============fids 集合:");
                        log.debug(fids);
                        for _, fid in ipairs(fids) do
                            if string.len(fid) > 0 then
                                table.insert(forumIds, fid)
                            end
                        end
                    end
                end
            end
        end
    end
    return forumIds;
end

------------------------------------------------------------------------------------------
-- 通过区哉id获取bbs信息.
-- @param #string bbsid
function BbsService:getBbsByRegionId(regionId)
    if regionId == nil or string.len(regionId) == 0 then
        error("regionId不能为空.")
    end
    local db = SsdbUtil:getDb()
    local rbbsid, err = db:hget("social_bbs_region_" .. regionId, "bbs_id")
    log.debug("regionid:" .. regionId .. "对应的缓存中的bbsid:" .. rbbsid[1])
    util:log_r_keys("social_bbs_region_" .. regionId, "hget")

    if rbbsid == nil or string.len(rbbsid[1]) == 0 then
        error("缓存中bbsid 为空.")
    end
    local bbsid = rbbsid[1]
    return self:getBbsById(bbsid)
end

------------------------------------------------------------------------------------------------------------------------
-- @param #table queryResult
-- 学校的单独处理
local function getSchollList(queryResult)
    local schoollist = queryResult.school_list;
    local db = SsdbUtil:getDb()
    local list = {}
    if schoollist ~= nil and #schoollist > 0 then
        for j = 1, #schoollist do
            local resTempSchoolResult = {}
            resTempSchoolResult.id = schoollist[j].school_id
            local rbbsid = db:hget("social_bbs_region_" .. schoollist[j].school_id, "bbs_id")
            if rbbsid and #rbbsid > 0 and string.len(rbbsid[1]) > 0 then
                local keys = { "total_today", "total_topic", "total_yestoday", "total", "logo_url", "icon_url" }
                local bbsResult = db:multi_hget("social_bbs_" .. rbbsid[1], unpack(keys))
                if bbsResult and #bbsResult > 0 then
                    local bbs = util:multi_hget(bbsResult, keys) --工具实现对multi_hget解析
                    local totalService = require("social.service.BbsTotalService")
                    resTempSchoolResult.total = totalService:getHistoryPostTotal(rbbsid[1]);
                    resTempSchoolResult.total_topic = totalService:getTopicTotalNumber(rbbsid[1]);
                    resTempSchoolResult.logo_url = bbs.logo_url;
                    resTempSchoolResult.isopen = true
                    resTempSchoolResult.icon_url = bbs.icon_url;
                end
            else
                resTempSchoolResult.total = 0;
                resTempSchoolResult.total_topic = 0;
                resTempSchoolResult.logo_url = "";
                resTempSchoolResult.icon_url = "";
                resTempSchoolResult.isopen = false
            end
            resTempSchoolResult.name = schoollist[j].school_name
            resTempSchoolResult.type_name = schoollist[j].school_type_name
            resTempSchoolResult.type = schoollist[j].school_type
            table.insert(list, resTempSchoolResult);
        end
    end
    return list;
end


------------------------------------------------------------------------------------------
--- 获取机构信息
--- 省101 市102 区103 校104 班105
--- 机构类型：1省，2市，3区，4校，5分校，6部门，7班级
local function getOrgInfoList(regionId, orgType)
    local orgService = require "base.org.services.OrgService";
    local constant = require("social.common.constant")
    local _orgType = constant.convert(orgType);
    local resultObj = orgService:getAsyncOrgTree(regionId, _orgType, 1); --是否获取下级单位：0获取当前， 1获取下级
    local list = {}
    if resultObj then
        local db = SsdbUtil:getDb()
        for i = 1, #resultObj do
            local result = {}
            result.id = resultObj[i].id
            result.name = resultObj[i].name;
            result.org_type = resultObj[i].org_type
            local rbbsid = db:hget("social_bbs_region_" .. resultObj[i].id, "bbs_id")
            if rbbsid and #rbbsid > 0 and string.len(rbbsid[1]) > 0 then
                local keys = { "total_today", "total_topic", "total_yestoday", "total", "logo_url", "icon_url" }
                local bbsResult = db:multi_hget("social_bbs_" .. rbbsid[1], unpack(keys))
                if bbsResult and #bbsResult > 0 then
                    local bbs = util:multi_hget(bbsResult, keys) --工具实现对multi_hget解析
                    local totalService = require("social.service.BbsTotalService")
                    result.total = totalService:getHistoryPostTotal(rbbsid[1]);
                    result.total_topic = totalService.getTopicTotalNumber(rbbsid[1]);
                    result.logo_url = bbs.logo_url;
                    result.isopen = true
                    result.icon_url = bbs.icon_url;
                end
            else
                result.total = 0;
                result.total_topic = 0;
                result.logo_url = "";
                result.icon_url = "";
                result.isopen = false
            end
            table.insert(list, result);
        end
    end
    return list;
end

------------------------------------------------------------------------------------------
-- 通过区哉id获取bbs信息.
-- @orgType #string orgType
-- @param #string bbsid
function BbsService:getBbsList(regionId, orgType, pageNumber, pageSize)
    if regionId == nil or string.len(regionId) == 0 then
        error("regionId不能为空.")
    end
    if pageNumber == nil or string.len(pageNumber) == 0 then
        error("pageNumber不能为空.")
    end
    if pageSize == nil or string.len(pageSize) == 0 then
        error("pageSize不能为空.")
    end
    local result = {}
    if orgType == nil or string.len(orgType) == 0 then
        log.debug("orgType 不能为空.")
        return result;
    end
    --如果是103是区的类型，则获取所有学校的bbs信息
    if orgType == 103 then
        local queryParam = { org_id = regionId, org_type = 3, pageNumber = pageNumber, pageSize = pageSize }
        local schoolService = require "base.org.services.SchoolService";
        local queryResult = schoolService:querySchoolByOrgWithPage(queryParam);
        if queryResult then
            result.pageSize = queryResult.pageSize;
            result.pageNumber = queryResult.pageNumber;
            result.totalPage = queryResult.totalPage;
            result.totalRow = queryResult.totalRow;
            result.list = getSchollList(queryResult)
        else
            return false;
        end
    else
        result.list = getOrgInfoList(regionId, orgType)
    end
    return result;
end

------------------------------------------------------------------------------------------
--- 回复信息后修改模块信息
-- @param #string lastpostid
-- @param #string forumid
function BbsService:updatePostForumToDb(forumid, lastpostid)
    if forumid == nil or string.len(forumid) == 0 then
        error("forumid不能为空.")
    end
    if lastpostid == nil or string.len(lastpostid) == 0 then
        error("last_post_id不能为空.")
    end

    local sql = "UPDATE T_SOCIAL_BBS_FORUM SET LAST_POST_ID=" .. lastpostid .. ",LAST_POST_TIME=now()" .. " WHERE ID=" .. forumid;
    log.debug("updatePostForumToDb:")
    log.debug("sql:" .. sql)
    local queryResult = DBUtil:querySingleSql(sql);
    return queryResult;
end

------------------------------------------------------------------------------------------
-- 修改最后回复帖的时间
-- @param #string forumid
-- @param #string lastpostid
function BbsService:updatePostForumToSsdb(forumid, lastpostid)
    log.debug("updatePostForumToSsdb start.")
    local db = SsdbUtil:getDb();
    local currentTime = date(os.date("%Y%m%d%H%M%S")):fmt("%Y-%m-%d %H:%M:%S")
    local status, err = db:multi_hset("social_bbs_forum_" .. forumid, "last_post_id", lastpostid, "last_post_time", currentTime)
    if status then
        log.debug("updatePostForumToSsdb 修改缓存成功.")
    else
        log.debug("updatePostForumToSsdb 修改缓存失败.")
    end
    util:logkeys("social_bbs_forum_" .. forumid, "multi_hset") --把key记录到日志文件 中.
    log.debug("updatePostForumToSsdb end.")
end

return BbsService;
