--[[
论坛添加或编辑分区
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
local bbs_id = args["bbs_id"]
local name = args["name"]
local sequence = args["sequence"]
if not bbs_id or len(bbs_id) == 0 or
	not name or len(name) == 0 or
	not sequence or len(sequence) == 0 then
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

if partition_id and len(partition_id) > 0 then
	--update mysql
	local usql = "update t_social_bbs_partition set name = "..quote(name).." where id = "..partition_id
	local uresutl, err = mysql:query(usql)
	if not uresutl then
    	say("{\"success\":false,\"info\":\""..err.."\"}")
   		return
	end

	--update ssdb
	ssdb:hset("social_bbs_partition_"..partition_id, "name", name)
else
	--insert mysql
	partition_id = ssdb:incr("social_bbs_partition_pk")[1]

	local isql = "insert into t_social_bbs_partition(id,bbs_id,name,sequence) values("..
	partition_id..","..bbs_id..","..quote(name)..","..sequence..")"
	local uresutl, err = mysql:query(isql)
	if not uresutl then
    	say("{\"success\":false,\"info\":\""..err.."\"}")
   		return
	end

	--insert ssdb
	local partition = {}
	partition.id = partition_id
	partition.bbs_id = bbs_id
	partition.name = name
	partition.sequence = sequence
	partition.b_delete = 0
	ssdb:multi_hset("social_bbs_partition_"..partition_id, partition)

	local pids_t, err = ssdb:hget("social_bbs_include_partition", "bbs_id_"..bbs_id)
	local pids = ""
	if pids_t and len(pids_t[1]) > 0 then
		pids = pids_t[1]..","..partition_id
	else
		pids = partition_id
	end
	ssdb:hset("social_bbs_include_partition", "bbs_id_"..bbs_id, pids)
end

--return
local rr = {}
rr.success = true
rr.partition_id = partition_id
rr.bbs_id = bbs_id
rr.name = name
rr.sequence = sequence
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)