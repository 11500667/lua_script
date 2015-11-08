--[[
调整分区顺序
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

local bbs_id = args["bbs_id"]
local partition_list = args["partition_list"]
if not partition_list or len(partition_list) == 0 or
    not bbs_id or len(bbs_id) == 0 then
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

local partition_t = cjson.decode(partition_list)
local pids = ""
for i=1, #partition_t do
    local partition_id = partition_t[i].partition_id
    local sequence = partition_t[i].sequence
    --update mysql
    local usql = "update t_social_bbs_partition set sequence = "..sequence.." where id = "..partition_id
    local uresult, err = mysql:query(usql)
    if not uresult then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --update ssdb
    ssdb:hset("social_bbs_partition_"..partition_id, "sequence", sequence)
    --ssdb论坛下分区
    pids = pids..","..partition_id
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