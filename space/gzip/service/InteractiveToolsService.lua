--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/19
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
-- 互动工具gzip压缩

local log = require("social.common.log")
local SsdbUtil = require("social.common.ssdbutil")
local TS = require "resty.TS"
local cjson = require "cjson"
local _M = {}
local function hasKey(t, cmpKey)
    for k, _ in pairs(t) do
        if k == cmpKey then
            return true
        end
    end
    return false
end

local function messageBoard(param, person_id, identity_id)
    local postService = require("social.service.BbsPostService")
    local topicService = require("social.service.BbsTopicService")

    local topicResult = topicService:getTopicByTypeIdAndType("spacemessageBoard" .. person_id .. identity_id, 2)
    local topicid;
    if topicResult and topicResult[1] then
        topicid = topicResult[1]['id']
    else
        return {};
    end
    local page_size = 5;
    local page_num = 1;
    local result = postService:getPostsFromDb(nil, nil, topicid, page_num, page_size, 1)
    topicService:updateTopicViewCountToDb(topicid)
    topicService:updateTopicViewCountToSsdb(topicid)

    return result
end

--data:{"random_num":creatRandomNum(),
--    "message_type": 1,
--    "person_id": parseInt(identity_id) >100 ?"":person_id,
--    "identity_id": parseInt(identity_id) >100 ?"":identity_id,
--    "page_size": page_size,
--    "page_num": 1,
--    "org_id": parseInt(identity_id) >100 ?org_id:""
--},
local function activeShare(param, person_id, identity_id, org_id)
    local service = require("space.activity_share.service.ActivityShareService")
    local person_id = ((tonumber(identity_id) > 100) and "") or person_id
    local identity_id = ((tonumber(identity_id) > 100) and "") or identity_id
    local page_size = 10;
    local page_num = 1;
    local org_id = ((tonumber(identity_id) > 100) and org_id) or ""
    local message_type = 1
    local param_t = { person_id = person_id, identity_id = identity_id, message_type = message_type, page_num = page_num, page_size = page_size, orgid = org_id }
    local result = service.list(param_t)
    return result;
end

--
--data:{"random_num":creatRandomNum(),
--    "person_id":person_id,
--    "message_type":1,
--    "identity_id":identity_id,
--    "pageSize":settings.self_setting.post_num,
--    "pageNumber":1
--},

local function myPost(param, person_id, identity_id)
    local topicService = require("social.service.BbsTopicService")
    local personId = person_id
    local identityId = identity_id
    local messageType = 1
    local pageNumber = 1
    local pageSize = tonumber(param.post_num)
    local result = topicService:getTopicListByUserInfo(personId, identityId, messageType, pageNumber, pageSize)
    return result;
end

--data:{"random_num":creatRandomNum(),
--    "type": 1,
--    "personid": person_id,
--    "identityid": identity_id,
--    "page_size": page_size,
--    "page_num": 1
--},
local function myVisitor(param, person_id, identity_id)
    local type = 1;
    local personid = person_id;
    local identityid = identity_id;
    local page_size = 16;
    local page_num = 1;
    local service = require("space.attention.service.AttentionService")
    local list, totalRow, totalPage = service.accesslist(personid, identityid, type, page_size, page_num)
    local result = { list = {} }
    result.list = list
    result.total_row = totalRow
    result.total_page = totalPage
    result.page_size = page_size
    result.page_num = page_num
    return result;
end



local function myAttention(param, person_id, identity_id)
    local service = require("space.attention.service.AttentionService")
    local personid = person_id --关注人id
    local identityid = identity_id --关注人id
    --    local b_personid = param.b_personid --被关注人id
    --    local b_identityid = param.b_identityid --被关注人的身份.
    local page_size = 16 --被关注人的身份.
    local page_num = 1 --被关注人的身份.
    local result = { list = {} }
    local list, totalRow, totalPage = service.queryAttention({ personid = personid, identityid = identityid, page_size = tonumber(page_size), page_num = tonumber(page_num) })
    result.list = list
    result.total_row = totalRow
    result.total_page = totalPage
    result.page_size = page_size
    result.page_num = page_num
    return result;
end

local function myFriends(param, person_id, identity_id)
    local person_id = person_id;
    local identity_id = identity_id;
    local url = string.format("/dsideal_yy/friend/getFriends?person_id=%s&identity_id=%s", person_id, identity_id);
    local data = ngx.location.capture(url)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t;
end

--函数table.
local function_table = {
    messageBoard = messageBoard, --留言版.
    activeShare = activeShare,
    myPost = myPost,
    myVisitor = myVisitor,
    myAttention = myAttention,
    myFriends = myFriends
}

--压缩数据
local function zipData(result, file_name)
    local file = io.open("/usr/local/openresty/nginx/html/interactive/" .. file_name, "w")
    cjson.encode_empty_table_as_object(false)
    file:write(cjson.encode(result))
    file:close()
    os.execute("gzip -f -9 /usr/local/openresty/nginx/html/interactive/" .. file_name)
end

--解析空间json
local function parseSpaceJsonAndRequestData(person_id, identity_id, org_id)
    local db = SsdbUtil:getDb()
    cjson.encode_empty_table_as_object(false)
    local json = db:get("space_info_" .. person_id .. "_" .. identity_id)
    --log.debug(json)
    local result = {}
    if json and json[1] and string.len(json[1]) > 0 then
        local jsonResult = cjson.decode(json[1])
        local setting_t = jsonResult['ALL_Setting']
        for k, _ in pairs(setting_t) do
            local _k = string.sub(k, 1, -7)
            log.debug(_k)
            local b = hasKey(function_table, _k); --判断是否有此key,如果没有此key跳 出循环.
            log.debug(b)
            repeat
                if not b then
                    break;
                end
                local status, _result = pcall(function_table[_k], setting_t[k]['self_setting'], person_id, identity_id, org_id);
                log.debug(status)
                log.debug(_result);
                if not status then
                    _result = { success = false, info = "请求数据失败." }
                else
                    _result.success = true
                end

                result[k] = _result
            until true
            --table.insert(result, { [k] = _result }) --返回json装载到table里面
        end
    end
    return result;
end



function _M.generateBakToolsJson(person_id, identity_id, login, org_id)

    local db = SsdbUtil:getDb()
    local ts = db:get("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_ts")[1]
    local last_ts = db:get("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_ts")[1];

    local nologin_ts = db:get("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_nologin_ts")[1]
    local nologin_last_ts = db:get("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_nologin_ts")[1];

    local file_name = "space_" .. person_id .. "_" .. identity_id .. "_interaction_data.json";
    local no_login_file_name = "space_" .. person_id .. "_" .. identity_id .. "_interaction_data_no_login.json";
    log.debug(ts)
    log.debug(last_ts)
    log.debug(nologin_ts)
    log.debug(nologin_last_ts)
    --or nologin_ts ~= nologin_last_ts
    if ts == nil or string.len(ts) == 0 or last_ts == nil or string.len(last_ts) == 0 or ts ~= last_ts then
        if login == "1" then
            local result = parseSpaceJsonAndRequestData(person_id, identity_id, org_id)
            zipData(result, file_name)
            local t1 = TS.getTs()
            db:set("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_ts", t1)
            db:set("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_ts", t1)
        end
    else
        log.debug("登录，不需要重新生成.")
    end
    if nologin_ts == nil or string.len(nologin_ts) == 0 or nologin_last_ts == nil or string.len(nologin_last_ts) == 0 or nologin_ts ~= nologin_last_ts then
        if login == "0" then
            local result = parseSpaceJsonAndRequestData(person_id, identity_id, org_id)
            zipData(result, no_login_file_name)
            local t1 = TS.getTs()
            db:set("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_nologin_ts", t1)
            db:set("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_interaction_nologin_ts", t1)
        end
    else
        log.debug("未登录，不需要重新生成.")
    end
end

return _M;