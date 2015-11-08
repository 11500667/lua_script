--[[
根据notice_id查看
@Author  feiliming
@Date    2015-7-16
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--get args
local notice_id = ngx.var.arg_notice_id
if not notice_id or len(notice_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！！！！\"}")
    return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local hr, err = ssdb:multi_hget("social_notice_"..notice_id, "title", "overview", "person_id", "identity_id", "create_time", "content", "category_id", "register_id", "thumbnail", "attachments", "view_count", "notice_type", "stage_id", "stage_name", "subject_id", "subject_name", "org_id")
if not hr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local notice_t = {}
if hr and hr[1] ~= "ok" and hr[1] ~= "not_find" then
    notice_t.notice_id = notice_id
    notice_t.title = hr[2] and ngx.decode_base64(hr[2]) or ""
    notice_t.overview = hr[4] and ngx.decode_base64(hr[4]) or ""
    notice_t.person_id = hr[6]
    local aService = require "space.services.PersonAndOrgBaseInfoService"
    notice_t.person_name = aService:getPersonNameByPersonIdAndIdentityId(hr[6], hr[8])
    notice_t.identity_id = hr[8]
    notice_t.create_time = hr[10]
    notice_t.content = hr[12] and ngx.decode_base64(hr[12]) or ""
    local category_id = hr[14]
    notice_t.category_id = category_id
    if category_id ~= "-1" then
        local category_name = ssdb:hget("social_notice_category_"..category_id, "category_name")
        category_name = category_name and category_name[1] or ""
        notice_t.category_name = category_name
    end
    notice_t.register_id = hr[16]
    notice_t.thumbnail = hr[18] or ""
    notice_t.thumbnail_list = hr[18] and len(hr[18]) > 0 and aService:getResById1(hr[18]) or ""
    notice_t.attachments = hr[20] or ""
    notice_t.attachments_list = hr[20] and len(hr[20]) > 0 and aService:getResById1(hr[20]) or ""
    notice_t.view_count = hr[22] or "0"
    notice_t.notice_type = hr[24] or ""
    notice_t.stage_id = hr[26] or ""
    notice_t.stage_name = hr[28] or ""
    notice_t.subject_id = hr[30] or ""
    notice_t.subject_name = hr[32] or ""
    notice_t.org_id = hr[34] or ""
end

--return
local rr = {}
rr.success = true
rr.notice = notice_t

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)