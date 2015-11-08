--[[
通知接收者使用，查看接收到的通知
@Author  feiliming
@Date    2015-7-17
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local ssdblib = require "resty.ssdb"

--get args
local register_id = ngx.var.arg_register_id
local person_id = ngx.var.arg_person_id
local identity_id = ngx.var.arg_identity_id
local page_size = ngx.var.arg_page_size
local page_number = ngx.var.arg_page_number
if not person_id or len(person_id) == 0 or 
    not identity_id or len(identity_id) == 0 or 
	not page_size or len(page_size) == 0 or 
	not page_number or len(page_number) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
page_size = tonumber(page_size)
page_number = tonumber(page_number)

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

local register_sql = ""
if register_id and len(register_id) > 0 then
    register_sql = " and register_id = "..quote(register_id)
end

local sqlcount = "SELECT count(*) as totalRow FROM t_social_notice_receive t where receive_person_id = "..quote(person_id).." and receive_identity_id = "..quote(identity_id).." and b_delete = 0 "..register_sql
ngx.log(ngx.ERR, "111==="..sqlcount)
local totalRow_t, err = mysql:query(sqlcount)
if not totalRow_t then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local total_row = tonumber(totalRow_t[1].totalRow)
local total_page = math.floor((total_row + page_size - 1) / page_size)

--page
local offset = page_size*page_number - page_size
local limit = page_size
local sql = "SELECT * FROM t_social_notice_receive t where receive_person_id = "..quote(person_id).." and receive_identity_id = "..quote(identity_id).." and b_delete = 0 "..register_sql.." LIMIT "..offset..", "..page_size
ngx.log(ngx.ERR, "111==="..sql)
local receivelist = mysql:query(sql)
if not receivelist then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local aService = require "space.services.PersonAndOrgBaseInfoService"
for i=1,#receivelist do
	local pid = receivelist[i].receive_person_id
	local iid = receivelist[i].receive_identity_id
    local notice_id = receivelist[i].notice_id
	local person_name = aService:getPersonNameByPersonIdAndIdentityId(pid, iid)
	receivelist[i].receive_person_name = person_name

    local hr, err = ssdb:multi_hget("social_notice_"..notice_id, "title", "overview", "person_id", "identity_id", "create_time", "content", "category_id", "register_id", "thumbnail", "attachments", "view_count", "notice_type")
    if not hr then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end

    local notice_t = {}
    if hr and hr[1] ~= "ok" and hr[1] ~= "not_find" then
        receivelist[i].title = hr[2] and ngx.decode_base64(hr[2]) or ""
        receivelist[i].overview = hr[4] and ngx.decode_base64(hr[4]) or ""
        receivelist[i].person_id = hr[6]
        receivelist[i].person_name = aService:getPersonNameByPersonIdAndIdentityId(hr[6], hr[8])
        receivelist[i].identity_id = hr[8]
        --receivelist[i].create_time = hr[10]
        receivelist[i].content = hr[12] and ngx.decode_base64(hr[12]) or ""
        local category_id = hr[14]
        receivelist[i].category_id = category_id
        if category_id ~= "-1" then
            local category_name = ssdb:hget("social_notice_category_"..category_id, "category_name")
            category_name = category_name and category_name[1] or ""
            receivelist[i].category_name = category_name
        end
        receivelist[i].thumbnail = hr[18]
        --receivelist[i].thumbnail_list = hr[18] and len(hr[18]) > 0 and aService:getResById1(hr[18]) or ""
        receivelist[i].attachments = hr[20]
        --receivelist[i].attachments_list = hr[20] and len(hr[20]) > 0 and aService:getResById1(hr[20]) or ""
        receivelist[i].view_count = hr[22]
        receivelist[i].notice_type = hr[24]
    end
end

--return
local rr = {}
rr.success = true
rr.total_row = total_row
rr.total_page = total_page
rr.page_number = page_number
rr.page_size = page_size
rr.list = receivelist

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)