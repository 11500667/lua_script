--[[
删除版块
@Author feiliming
@Date   2015-3-23
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

--get args
local forum_id = ngx.var.arg_forum_id

if not forum_id or len(forum_id) == 0 then
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

--update mysql
local ssql = "update t_social_bbs_forum set b_delete = 1 where id = "..forum_id
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--update ssdb
ssdb:hset("social_bbs_forum_"..forum_id, "b_delete", 1)

local partition_id, err = ssdb:hget("social_bbs_forum_"..forum_id, "partition_id")[1]
local fids, err = ssdb:hget("social_bbs_include_forum", "partition_id_"..partition_id)[1]
if fids and len(fids) > 0 then
	fids = string.gsub(fids, forum_id..",", "")
	fids = string.gsub(fids, ","..forum_id, "")
	fids = string.gsub(fids, forum_id, "")
end
ssdb:hset("social_bbs_include_forum", "partition_id_"..partition_id, fids)

--return
local rr = {}
rr.success = true
rr.info = "操作成功!"
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)