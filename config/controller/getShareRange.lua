--[[
#申健  2015-06-01
#描述：判断对象是否允许修改名称
]]

-- 1.获取参数
local personId   = ngx.var.cookie_person_id;
local identityId = ngx.var.cookie_identity_id;

ngx.log(ngx.ERR, "[sj_log] -> [config] -> personId :[", type(personId), "][", personId, "], identityId : [", type(identityId), "][", identityId, "]");

local cacheUtil = require "common.CacheUtil";
local personCache = cacheUtil: hmget("person_" .. personId .. "_" .. identityId, "sheng", "shi", "qu", "xiao", "bm");
if not personCache then
    ngx.say("{\"success\":false,\"info\":\"获取用户缓存信息失败\"}");
    return;
end
personCache["all"] = 1;

-- 获取用户可共享的组织机构（全国、省、市、区、校、部门）
local rangeTable = {};
local orgList = {};
for index = 1, #v_share_range do 
    local configItem    = v_share_range[index];
    local orgItem       = {};

    if configItem["display"] == true then
        orgItem["org_name"] = configItem["name"];
        orgItem["display"]  = configItem["display"];
        -- ngx.log(ngx.ERR, "[sj_log] -> [config] -> redis-key -> ", configItem["redis_key"]);
        orgItem["org_id"]   = personCache[configItem["redis_key"]];
		orgItem["input_id"]   = configItem["input_id"];

        table.insert(orgList, orgItem);
    end
end
rangeTable["org_List"] = orgList;



-- 获取用户可共享的群组
local groupList = {}
if v_share_group then
    local realGroupTable = cacheUtil: smembers("group_" .. personId .. "_" .. identityId .. "_real");
    if not realGroupTable then
        ngx.say("{\"success\":false,\"info\":\"获取用户所在的群组失败\"}");
        return;
    end
    for index = 1, #realGroupTable do
        local groupId   = realGroupTable[index];
        local groupName = cacheUtil: hget("groupinfo_" .. groupId, "org_name");
        
        local groupItem = {};
        groupItem["group_id"]   = groupId;
        groupItem["group_name"] = groupName;

        table.insert(groupList, groupItem);
    end
end
rangeTable["group_List"] = groupList;

rangeTable["success"] = true;

local cjson = require "cjson";
ngx.log(ngx.ERR, "[sj_log] -> [config] -> rangeTable: [", cjson.encode(rangeTable), "]");

ngx.print(cjson.encode(rangeTable));