--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/9/2
-- Time: 15:29
-- To change this template use File | Settings | File Templates.
--
local web = require("social.router.web")
local request = require("social.common.request")
local cjson = require "cjson"
local context = ngx.var.path_uri --有权限的context.
local log = require("social.common.log")
local groupModel = require "base.group.model.groupMember";
local SsdbUtil = require("social.common.ssdbutil")
local function getMemberByparams()
    local groupId = request:getNumParam("groupId", false, false)
    local nodeId = request:getNumParam("nodeId", false, false)
    local rangeType = request:getNumParam("rangeType", false, false)
    local orgType = request:getNumParam("orgType", false, false)
    local keyword = request:getStrParam("keyword", false, false)
    local pageNumber = request:getNumParam("pageNumber", false, false)
    local pageSize = request:getNumParam("pageSize", false, true)
    local member_type = request:getNumParam("member_type", false, false)
    local stage_id = request:getNumParam("stage_id", false, false)
    local subject_id = request:getNumParam("subject_id", false, false)
    log.debug(groupId)
    log.debug(nodeId)
    log.debug(rangeType)
    log.debug(orgType)
    log.debug(keyword)
    log.debug(pageNumber)
    log.debug(pageSize)
    log.debug(member_type)
    log.debug(stage_id)
    log.debug(subject_id)
    local result, returnjson = groupModel.getMemberByparams(groupId, nodeId, rangeType, orgType, keyword, pageNumber, pageSize, member_type, stage_id, subject_id);
    log.debug(returnjson);
    if result then
        local table_list = returnjson.table_List;
        for i = 1, #table_list do
            local person_id = table_list[i].PERSON_ID
            local identity_id = table_list[i].identity_id;
            local info_key = "space_ajson_personbaseinfo_" .. person_id .."_"..identity_id;
            local ssdb = SsdbUtil:getDb()
            local logoResult = ssdb:get(info_key)
            if logoResult and logoResult[1] and string.len(logoResult[1]) > 0 then
                local jsonObj = cjson.decode(logoResult[1])
                local logo_url = jsonObj.space_avatar_fileid
                table_list[i]['logo_url'] = logo_url;
            end
        end
        ngx.say(cjson.encode(returnjson));
    else
        ngx.say(cjson.encode({success = false}));
    end
end

-- 配置url.
-- 按功能分
local urls = {
    context .. '/getMemberByparams', getMemberByparams,
}
local app = web.application(urls, nil)
app:start()
