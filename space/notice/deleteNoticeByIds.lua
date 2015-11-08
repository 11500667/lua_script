--[[
批量删除新闻、通知、公告
@Author  feiliming
@Date    2015-7-17
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
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

local notice_ids = args["notice_ids"]
if not notice_ids or len(notice_ids) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！！！\"}")
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

local nids_t = Split(notice_ids, ",")

local update_ts = TS.getTs()
for _, nid in ipairs(nids_t) do
    local dsql1 = "update t_social_notice set update_ts = "..update_ts..", b_delete = 1 where notice_id = "..quote(nid)
    mysql:query(dsql1)
    --删除通知时，接收记录不删除
    --local dsql2 = "update t_social_notice_receive set b_delete = 1 where notice_id = "..quote(nid)
    --mysql:query(dsql2)
end

--return
local rr = {}
rr.success = true

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)