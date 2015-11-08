--[[
删除好友
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
if not friend_id or len(friend_id) == 0 then
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

--return
local rr = {}

local t0 = ssdb:multi_hget("social_friend_"..friend_id, "person_id", "identity_id", "fperson_id", "fidentity_id", "group_id")
if t0 and #t0 > 0 and t0[1] ~= "ok" and t0[1] ~= "not_found" then
    local person_id = t0[2]
    local identity_id = t0[4]
    local fperson_id = t0[6]
    local fidentity_id = t0[8]
    local group_id = t0[10]
    ngx.log(ngx.ERR, "=="..person_id.."=="..identity_id.."=="..fperson_id.."=="..fidentity_id.."=="..group_id)
    --从我好友里删除
    local dsql1 = "delete from t_social_friend where friend_id = "..friend_id
    local dresutl1, err = mysql:query(dsql1)
    if not dresutl1 then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --1好友,2全部好友排序,3分组好友排序,4好友标志
    ssdb:hclear("social_friend_"..friend_id)
    ssdb:zdel("social_friend_sorted_"..identity_id.."_"..person_id, friend_id) 
    ssdb:zdel("social_friend_group_friend_sorted_"..group_id, friend_id)
    ssdb:hdel("social_friend", identity_id.."_"..person_id.."_"..fidentity_id.."_"..fperson_id)

    --从好友里删除我
    local ssql = "select friend_id,group_id from t_social_friend where person_id = "..fperson_id.." and identity_id = "..fidentity_id..
        " and fperson_id = "..person_id.." and fidentity_id = "..identity_id
    local sresutl, err = mysql:query(ssql)
    if not sresutl then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    local friend_id2 = sresutl[1].friend_id
    local group_id2 = sresutl[1].group_id
    local dsql2 = "delete from t_social_friend where friend_id = "..identity_id
    local dresutl2, err = mysql:query(dsql2)
    if not dresutl2 then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --1好友,2全部好友排序,3分组好友排序,4好友标志
    ssdb:hclear("social_friend_"..friend_id2)
    ssdb:zdel("social_friend_sorted_"..fidentity_id.."_"..fperson_id, friend_id2) 
    ssdb:zdel("social_friend_group_friend_sorted_"..group_id2, friend_id2)
    ssdb:hdel("social_friend", fidentity_id.."_"..fperson_id.."_"..identity_id.."_"..person_id)

    --更新张海的gzip的ts值
    --local service = require "space.gzip.service.InteractiveToolsUpdateTsService"
    --service.updateTs(person_id,identity_id)
    --service.updateTs(fperson_id,fidentity_id)

    rr.success = true
    rr.info = "删除成功！"
else
    rr.success = false
    rr.info = "没有找到这个好友！"
end    

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)