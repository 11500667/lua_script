--[[
开启关闭论坛
@Author feiliming
@Date   2015-3-23
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

--get args
local bbs_id = ngx.var.arg_bbs_id
local status = ngx.var.arg_status

if not bbs_id or len(bbs_id) == 0 or
	not status or len(status) == 0 then
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

--从mysql判断
local ssql = "select id,region_id,name,logo_url,icon_url,domain,status,social_type from t_social_bbs where id = "..bbs_id
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--update
if sresult and #sresult > 0 then
    --update mysql
	local usql = "UPDATE t_social_bbs SET status = "..quote(status).." WHERE id = "..bbs_id
    local uresult, err = mysql:query(usql)
    if not uresult then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --update ssdb
    ssdb:hset("social_bbs_"..bbs_id, "status", status)
end

--return
local rr = {}
rr.success = true
rr.info = "操作成功!"
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)