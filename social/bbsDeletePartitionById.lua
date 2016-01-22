--[[
删除分区
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
local partition_id = args["partition_id"]

if not partition_id or len(partition_id) == 0 then
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
local ssql = "update t_social_bbs_partition set b_delete = 1 where id = "..partition_id
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--update ssdb
ssdb:hset("social_bbs_partition_"..partition_id, "b_delete", 1)

local bbs_id, err = ssdb:hget("social_bbs_partition_"..partition_id, "bbs_id")[1]
local pids, err = ssdb:hget("social_bbs_include_partition", "bbs_id_"..bbs_id)[1]
if pids and len(pids) > 0 then
	pids = string.gsub(pids, partition_id..",", "")
	pids = string.gsub(pids, ","..partition_id, "")
	pids = string.gsub(pids, partition_id, "")
end
ssdb:hset("social_bbs_include_partition", "bbs_id_"..bbs_id, pids)

--return
local rr = {}
rr.success = true
rr.info = "操作成功!"
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)