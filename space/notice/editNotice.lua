--[[
编辑新闻通知公告
@Author  feiliming
@Date    2015-7-16
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"
local TS = require "resty.TS"

--post args
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local notice_id = args["notice_id"]
local title = args["title"]
local overview = args["overview"]
local content = args["content"]
local category_id = args["category_id"]
local thumbnail = args["thumbnail"]
local attachments = args["attachments"]

if not notice_id or len(notice_id) == 0 or 
    not title or len(title) == 0 or 
    not content or len(content) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

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

--default
local thumbnail_sql = thumbnail_id and ", thumbnail = "..quote(thumbnail_id) or ""
local attachments_sql = attachments and ", attachments = "..quote(attachments) or ""
local category_id_sql = category_id and ", category_id = "..quote(category_id) or ""
local overview_sql = overview and ", overview = "..quote(overview) or ""

local update_ts = TS.getTs()
local isql = "UPDATE t_social_notice SET title = "..quote(title)..overview_sql..
    ", content = "..quote(content)..category_id_sql..thumbnail_sql..
    attachments_sql..", update_ts = "..quote(update_ts).." where notice_id = "..quote(notice_id)

local ir, err = mysql:query(isql)
if not ir then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--正文插入到ssdb
--base64 encode
local title_base64 = title and ngx.encode_base64(title) or ""
local content_base64 = content and ngx.encode_base64(content) or ""

local notice_t = {}
notice_t.notice_id = notice_id
notice_t.title = title_base64
if overview then
    local overview_base64 = overview and ngx.encode_base64(overview) or ""
    notice_t.overview = overview_base64
end
notice_t.content = content_base64
if category_id then
    notice_t.category_id = category_id
end
if thumbnail then
    notice_t.thumbnail = thumbnail
end
if attachments then
    notice_t.attachments = attachments
end

local hr, err = ssdb:multi_hset("social_notice_"..notice_id, notice_t)
if not hr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--return
local rr = {}
rr.success = true

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)