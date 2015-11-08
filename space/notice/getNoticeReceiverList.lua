--[[
根据notice_id查看通知已读、回执状态
@Author  feiliming
@Date    2015-7-17
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local notice_id = ngx.var.arg_notice_id
local page_size = ngx.var.arg_page_size
local page_number = ngx.var.arg_page_number
if not notice_id or len(notice_id) == 0 or 
	not page_size or len(page_size) == 0 or 
	not page_number or len(page_number) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
page_size = tonumber(page_size)
page_number = tonumber(page_number)

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

local sqlcount = "SELECT count(*) as totalRow FROM t_social_notice_receive t where notice_id = "..quote(notice_id)
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
local sql = "SELECT * FROM t_social_notice_receive t where notice_id = "..quote(notice_id).." LIMIT "..offset..", "..page_size
local receivelist = mysql:query(sql)
if not receivelist then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local aService = require "space.services.PersonAndOrgBaseInfoService"
for i=1,#receivelist do
	local pid = receivelist[i].receive_person_id
	local iid = receivelist[i].receive_identity_id
	local person_name = aService:getPersonNameByPersonIdAndIdentityId(pid, iid)
	receivelist[i].receive_person_name = person_name
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