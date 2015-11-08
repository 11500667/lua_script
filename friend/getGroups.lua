--[[
查询用户所有分组
@Author feiliming
@Date   2015-4-1
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

local person_id = args["person_id"]
local identity_id = args["identity_id"]
if not person_id or len(person_id) == 0 or
	not identity_id or len(identity_id) == 0 then
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

--get group
local groups = {}
local z0 = ssdb:zrange("social_friend_group_sorted_"..identity_id.."_"..person_id, 0, 10000)
if z0 and #z0 > 0 and z0[1] ~= "ok" and z0[1] ~= "not_found" then
    for i=1, #z0, 2 do
        local group_id = z0[i]
        local t0 = ssdb:multi_hget("social_friend_group_"..group_id, "group_name", "group_type", "sequence")
        if t0 and #t0 > 0 and t0[1] ~= "ok" and t0[1] ~= "not_found" then
            local group = {}
            group.group_id = group_id
            group.group_name = t0[2]
            group.person_id = person_id
            group.identity_id = identity_id
            group.group_type = t0[4]
            group.sequence = t0[6]
            local friend_num = ssdb:zsize("social_friend_group_friend_sorted_"..group_id)[1]
            group.friend_num = friend_num

            groups[#groups + 1] = group
        end
    end
else
    --判断默认分组是否存在，不存在则插入默认分组
    local ssql = "select group_id from t_social_friend_group where person_id = "..person_id.." and identity_id = "..identity_id.." and group_type = 1"
    local sresult, err = mysql:query(ssql)
    if not sresult then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    if sresult and #sresult == 0 then
        --insert mysql
        local group_id = ssdb:incr("t_social_friend_group_pk")[1]
        local group_type = 1
        local isql = "insert into t_social_friend_group(group_id, group_name, person_id, identity_id, group_type, sequence) values ("..
            group_id..", '我的好友' ,"..person_id..","..identity_id..","..group_type..", 0)"
        local iresutl, err = mysql:query(isql)
        if not iresutl then
            say("{\"success\":false,\"info\":\""..err.."\"}")
            return
        end
        --insert ssdb
        local group = {}
        group.group_id = group_id
        group.group_name = "我的好友"
        group.person_id = person_id
        group.identity_id = identity_id
        group.group_type = group_type
        group.sequence = 0
        group.friend_num = 0

        ssdb:multi_hset("social_friend_group_"..group_id, group)
        ssdb:zset("social_friend_group_sorted_"..identity_id.."_"..person_id, group_id, 0)

        groups[#groups + 1] = group
    end
end

--return
local rr = {}
rr.success = true
rr.groups = groups

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)