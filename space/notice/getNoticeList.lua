--[[
根据注册号查询列表
@Author  feiliming
@Date    2015-7-17
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

--get args
local register_id = ngx.var.arg_register_id
local category_id = ngx.var.arg_category_id
local org_ids = ngx.var.arg_org_ids
--local org_type = ngx.var.arg_org_type
local title = ngx.var.arg_title
local page_size = ngx.var.arg_page_size
local page_number = ngx.var.arg_page_number
local stage_id = ngx.var.arg_stage_id
local subject_id = ngx.var.arg_subject_id
local sort_type = ngx.var.arg_sort_type

if not register_id or len(register_id) == 0 or 
    not page_size or len(page_size) == 0 or 
    not page_number or len(page_number) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
page_size = tonumber(page_size)
page_number = tonumber(page_number)

--[[
if org_ids and len(org_ids) > 0 then
    if not org_type or len(org_type) == 0 then
        say("{\"success\":false,\"info\":\"org_type参数错误！\"}")
        return
    end
end
if org_type and len(org_type) > 0 then
    if not org_ids or len(org_ids) == 0 then
        say("{\"success\":false,\"info\":\"org_ids参数错误！\"}")
        return
    end
end
]]
--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--mysql
local mysql, err = mysqllib:new()
if not mysql then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local ok, err = mysql:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local category_id_filter = ""
if category_id and len(category_id) > 0 then
    category_id_filter = "filter=category_id,"..category_id..";"
end
local org_ids_filter = ""
if org_ids and len(org_ids) > 0 then
    --org_ids_filter = "filter=org_id,"..org_ids..";filter=org_type,"..org_type..";"
    org_ids_filter = "filter=org_id,"..org_ids..";"
end
local title_filter = ""
if title and len(title) > 0 then
    title = ngx.unescape_uri(title)
    title = ngx.decode_base64(title)
    title_filter = title..";"
end
local stage_id_filter = ""
if stage_id and len(stage_id) > 0 then
   stage_id_filter = "filter=stage_id,"..stage_id..";"
end
local subject_id_filter = ""
if subject_id and len(subject_id) > 0 then
   subject_id_filter = "filter=subject_id,"..subject_id..";"
end

local sort_type_sql = ""
if sort_type and  sort_type == "1" then
    sort_type_sql = "sort=attr_desc:ts;"
else
    sort_type_sql = "sort=attr_desc:view_count;" 
end

local offset = page_size*page_number - page_size
local limit = page_size
local ssql = "SELECT SQL_NO_CACHE ID FROM T_SOCIAL_NOTICE_SPHINXSE WHERE QUERY= '"..title_filter..org_ids_filter..category_id_filter..stage_id_filter..subject_id_filter..
    "filter=register_id,"..register_id..";filter=b_delete,0;"..sort_type_sql.."offset="..offset..";limit="..limit..";';SHOW ENGINE SPHINX STATUS;"
ngx.log(ngx.ERR,ssql)
local r, err = mysql:query(ssql)
if not r then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--去第二个结果集中的Status中截取总个数
local r2 = mysql:read_result()
local _,s_str = string.find(r2[1]["Status"],"found: ")
local e_str = string.find(r2[1]["Status"],", time:")
local total_row = string.sub(r2[1]["Status"],s_str+1,e_str-1)
local total_page = math.floor((total_row+page_size-1)/page_size)

local notice_list = {}
--ngx.log(ngx.ERR,cjson.encode(r))
local aService = require "space.services.PersonAndOrgBaseInfoService"
for _, v in ipairs(r) do
    local notice_id = v.ID
    local hr, err = ssdb:multi_hget("social_notice_"..notice_id, "title", "overview", "person_id", "identity_id", "create_time", "content", "category_id", "register_id", "thumbnail", "attachments", "view_count", "notice_type", "stage_id", "stage_name", "subject_id", "subject_name")
    if not hr then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --ngx.log(ngx.ERR,cjson.encode(hr))
    if hr and hr[1] ~= "ok" and hr[1] ~= "not_find" then
        local notice_t = {}
        notice_t.notice_id = notice_id
        notice_t.title = hr[2] and ngx.decode_base64(hr[2]) or ""
        notice_t.overview = hr[4] and ngx.decode_base64(hr[4]) or ""
        notice_t.person_id = hr[6]
        notice_t.person_name = aService:getPersonNameByPersonIdAndIdentityId(hr[6], hr[8])
        notice_t.identity_id = hr[8]
        notice_t.create_time = hr[10]
        notice_t.content = hr[12] and ngx.decode_base64(hr[12]) or ""
        local category_id = hr[14]
        notice_t.category_id = category_id
        --if category_id ~= "-1" then
        --    local category_name = ssdb:hget("social_notice_category_"..category_id, "category_name")
        --   category_name = category_name and category_name[1] or ""
        --    notice_t.category_name = category_name
        --end
        notice_t.register_id = hr[16]
        notice_t.thumbnail = hr[18] or ""
        --notice_t.thumbnail_list = hr[18] and len(hr[18]) > 0 and aService:getResById1(hr[18]) or ""
        notice_t.attachments = hr[20]
        --notice_t.attachments_list = hr[20] and len(hr[20]) > 0 and aService:getResById1(hr[20]) or ""
        notice_t.view_count = hr[22] or ""
        notice_t.notice_type = hr[24] or ""
        notice_t.stage_id = hr[26] or ""
        notice_t.stage_name = hr[28] or ""
        notice_t.subject_id = hr[30] or ""
        notice_t.subject_name = hr[32] or ""

        table.insert(notice_list, notice_t)
    end
end

--return
local rr = {}
rr.success = true
rr.total_row = total_row
rr.total_page = total_page
rr.page_number = page_number
rr.page_size = page_size
rr.list = notice_list

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)