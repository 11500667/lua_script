--[[
添加新闻通知公告
@Author  feiliming
@Date    2015-7-15
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

local register_id = args["register_id"]
local person_id = args["person_id"]
local identity_id = args["identity_id"]
local title = args["title"]
local overview = args["overview"]
local content = args["content"]
local category_id = args["category_id"]
local org_id = args["org_id"]
local org_type = args["org_type"]
local thumbnail = args["thumbnail"]
local attachments = args["attachments"]
--数据类型，1表示新闻，2表示通知
local notice_type = args["notice_type"]
--通知指定接收人的person_id和identi_id
local receive_json = args["receive_json"]
local stage_id = args["stage_id"]
local stage_name = args["stage_name"]
local subject_id = args["subject_id"]
local subject_name = args["subject_name"]
if not register_id or len(register_id) == 0 or 
    not person_id or len(person_id) == 0 or 
    not identity_id or len(identity_id) == 0 or 
    not title or len(title) == 0 or 
    not content or len(content) == 0 or 
    not notice_type or len(notice_type) == 0 then
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
category_id = category_id or "-1"
org_id = org_id or "-1"
org_type = org_type or "-1"
thumbnail = thumbnail or ""
attachments = attachments or ""
overview = overview or ""
stage_id = stage_id or "-1"
stage_name = stage_name or ""
subject_id = subject_id or "-1"
subject_name = subject_name or ""
local create_time = os.date("%Y-%m-%d %H:%M:%S")
local update_ts = TS.getTs()
local isql = "INSERT INTO t_social_notice(title, overview, person_id, identity_id, create_time, content, "..
    "category_id, org_id, org_type, register_id, ts, update_ts, thumbnail, attachments, view_count, b_delete, notice_type, stage_id, stage_name, subject_id, subject_name)"..
    " VALUES ("..quote(title)..", "..quote(overview)..", "..quote(person_id)..", "..quote(identity_id)..
    ", "..quote(create_time)..", "..quote(content)..", "..quote(category_id)..", "..quote(org_id)..
    ", "..quote(org_type)..", "..quote(register_id)..", "..quote(update_ts)..", "..quote(update_ts)..
    ", "..quote(thumbnail)..", "..quote(attachments)..", 0, 0, "..quote(notice_type)..","..quote(stage_id)..","..quote(stage_name)..","..quote(subject_id)..","..quote(subject_name)..")"

local ir, err = mysql:query(isql)
if not ir then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local notice_id = ir.insert_id
--发送给接收者
--ngx.log(ngx.ERR,receive_json)
local receive_t = receive_json and cjson.decode(receive_json) or {}
if receive_t and #receive_t > 0 then
    local rsql = "INSERT INTO t_social_notice_receive(register_id, notice_id, create_time, receive_person_id, receive_identity_id, read_flag, receipt_flag, b_delete) VALUES "
    local vsql_t = {}
    for _,v in pairs(receive_t) do
        local pid = v.person_id
        local iid = v.identity_id
        local vsql = "("..quote(register_id)..", "..quote(notice_id)..", "..quote(create_time)..", "..quote(pid)..", "..quote(iid).. 
            ",0 , 0, 0)"
        table.insert(vsql_t, vsql)
    end
    rsql = rsql..table.concat(vsql_t, ",")..";"
    local rir, err = mysql:query(rsql)
    if not rir then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
end

--正文插入到ssdb
--base64 encode
local title_base64 = overview and ngx.encode_base64(title) or ""
local content_base64 = content and ngx.encode_base64(content) or ""
local overview_base64 = overview and ngx.encode_base64(overview) or ""

local notice_t = {}
notice_t.notice_id = notice_id
notice_t.title = title_base64
notice_t.overview = overview_base64
notice_t.person_id = person_id
notice_t.identity_id = identity_id
notice_t.create_time = create_time
notice_t.content = content_base64
notice_t.category_id = category_id
notice_t.org_id = org_id
notice_t.org_type = org_type
notice_t.register_id = register_id
notice_t.thumbnail = thumbnail
notice_t.attachments = attachments
notice_t.view_count = 0
notice_t.b_delete = 0
notice_t.notice_type = notice_type
notice_t.stage_id = stage_id
notice_t.stage_name = stage_name
notice_t.subject_id = subject_id
notice_t.subject_name = subject_name

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