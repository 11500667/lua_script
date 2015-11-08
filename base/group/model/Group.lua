-- -------------------------------------------
-- 描述：群组功能 -> 群组的基础接口
-- 日期：2015年8月4日
-- -------------------------------------------
local _Group   = {}

local SSDBUtil  = require "common.SSDBUtil";
local cacheutil = require "common.CacheUtil";
local DBUtil    = require "common.DBUtil";
local cacheUtil = require "common.CacheUtil";

-- --------------------------------------------------------
-- 函数描述： 群组功能 -> 设置群组是否允许申请加入
-- 日    期： 2015年8月5日
-- 参    数： bRequest  是否允许加入：0不允许，1允许
-- 返 回 值： boolean   true设置成功，false设置失败
-- --------------------------------------------------------
local function setBRequest(groupId, bRequest)
    local sql = "UPDATE T_BASE_GROUP_NEW SET B_REQUEST = " .. bRequest .. " WHERE ID = " .. groupId .. ";";
    ngx.log(ngx.ERR, "[sj_log] -> sql:[", sql, "]");
    local result = DBUtil: querySingleSql(sql);
    if not result then
        return false;
    else
        return true;
    end
end

_Group.setBRequest = setBRequest;

-- --------------------------------------------------------
-- 函数描述： 群组功能 -> 解散群组
-- 日    期： 2015年8月10日
-- 返 回 值： boolean   true操作成功，false操作失败
-- --------------------------------------------------------
local function disbandGroup(groupId)
    
    local groupType = cacheUtil: hget("groupinfo_" .. groupId, "group_type");
    groupType = tonumber(groupType);

    local sql = "UPDATE T_BASE_GROUP_NEW SET B_USE = 0 WHERE ID = " .. groupId .. ";";
    local result = DBUtil: querySingleSql(sql);
    if not result then
        return false;
    else
        if groupType == 1 then -- 机构组
            sql = "SELECT ID, GROUP_ID, ORG_TYPE, ORG_ID, JOIN_TYPE, STAGE_ID, SUBJECT_ID, B_USE FROM    T_BASE_GROUP_ORG_NEW WHERE GROUP_ID = " .. groupId .. " AND B_USE = 1";

            local orgs = DBUtil: querySingleSql(sql);
            if not orgs then
                ngx.log(ngx.ERR, "[sj_log] -> [解散群组] -> 机构组下没有查询到机构");
                return false; 
            end

            orgType = { "", "BUREAU_ID", "ORG_ID", "DISTRICT_ID", "CITY_ID", "CLASS_ID"}

            for index, org in ipairs(orgs) do
                queryField = orgType[tonumber(org["ORG_TYPE"])];
                sql = "SELECT PERSON_ID, IDENTITY_ID FROM T_BASE_PERSON WHERE " .. queryField .. "=" .. org["ORG_ID"] .. ";";

                local members = DBUtil: querySingleSql(sql);
                if not members then
                    ngx.log(ngx.ERR, "[sj_log] -> [解散群组] -> 机构组下没有查询到成员");
                    return false; 
                end
                for index, person in ipairs(members) do
                    cacheUtil: srem("group_" .. person["PERSON_ID"] .. "_" .. person["IDENTITY_ID"], groupId);
                    cacheUtil: srem("group_" .. person["PERSON_ID"] .. "_" .. person["IDENTITY_ID"] .. "_real", groupId);
                end
            end
            
            -- 删除群主
            sql = "SELECT PERSON_ID, IDENTITY_ID FROM T_BASE_GROUP_MEMBER_NEW WHERE GROUP_ID = " .. groupId .. " AND MEMBER_TYPE = 0;";
            local master = DBUtil: querySingleSql(sql);
            if master then
                ngx.log(ngx.ERR, "\n删除群主的缓存\n");
                cacheUtil: srem("group_" .. master[1]["PERSON_ID"] .. "_" .. master[1]["IDENTITY_ID"], groupId);
                cacheUtil: srem("group_" .. master[1]["PERSON_ID"] .. "_" .. master[1]["IDENTITY_ID"] .. "_real", groupId);
            end

            sql = "UPDATE T_BASE_GROUP_MEMBER_NEW SET B_USE = 0 WHERE GROUP_ID = " .. groupId .. ";";
            DBUtil: querySingleSql(sql);

            sql = "UPDATE T_BASE_GROUP_ORG_NEW SET B_USE = 0 WHERE GROUP_ID = " .. groupId .. ";";
            DBUtil: querySingleSql(sql);

        elseif groupType == 2 then -- 人员组
            sql = "SELECT id, person_id, identity_id FROM T_BASE_GROUP_MEMBER_NEW WHERE GROUP_ID = " .. groupId .. " AND B_USE = 1;";
            local memberRes = DBUtil: querySingleSql(sql);
            ngx.log(ngx.ERR, "[sj_log] -> [解散群组] -> 查询群组下的成员的SQL：[", sql, "], 查询结果：[", encodeJson(memberRes), "]");
            if not memberRes then
                ngx.log(ngx.ERR, "[sj_log] -> [解散群组] -> 没有成员的返回值");
                return false;
            end
            for index, record in ipairs(memberRes) do
                cacheUtil: srem("group_" .. record["person_id"] .. "_" .. record["identity_id"], groupId);
                cacheUtil: srem("group_" .. record["person_id"] .. "_" .. record["identity_id"] .. "_real", groupId);
            end

            sql = "UPDATE T_BASE_GROUP_MEMBER_NEW SET B_USE = 0 WHERE GROUP_ID = " .. groupId .. ";";
            DBUtil: querySingleSql(sql);

            --sql = "UPDATE T_BASE_GROUP_ORG_NEW SET B_USE = 0 WHERE GROUP_ID = " .. groupId .. ";";
            --DBUtil: querySingleSql(sql);
        end
    end

    return true;
end

_Group.disbandGroup = disbandGroup;




return _Group;