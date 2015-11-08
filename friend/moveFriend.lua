--[[
移动好友
@Author feiliming
@Date   2015-4-2
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

local friend_id = args["friend_id"]
local to_group_id = args["to_group_id"]
if not friend_id or len(friend_id) == 0 or
	not to_group_id or len(to_group_id) == 0 then
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

local t0 = ssdb:multi_hget("social_friend_"..friend_id, "person_id", "identity_id", "fperson_id", "fidentity_id", "group_id", "sequence")
if t0 and #t0 > 0 and t0[1] ~= "ok" and t0[1] ~= "not_found" then
    local person_id = t0[2]
    local identity_id = t0[4]
    local fperson_id = t0[6]
    local fidentity_id = t0[8]
    local group_id = t0[10]
    local sequence = t0[12]
    --update mysql
    local usql = "update t_social_friend set group_id = "..to_group_id.." where friend_id = "..friend_id
    local uresutl, err = mysql:query(usql)
    if not uresutl then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --update ssdb
    ssdb:hset("social_friend_"..friend_id, "group_id", to_group_id)
    ssdb:zdel("social_friend_group_friend_sorted_"..group_id, friend_id)
    ssdb:zset("social_friend_group_friend_sorted_"..to_group_id, friend_id, sequence)

end

--return
local rr = {}
rr.success = true
rr.info = "移动成功！"

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)