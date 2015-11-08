--[[
删除分组
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
local group_id = args["group_id"]
if not person_id or len(person_id) == 0 or
	not identity_id or len(identity_id) == 0 or
	not group_id or len(group_id) == 0 then
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

--判断分组下是否有好友
local friend_num = ssdb:zsize("social_friend_group_friends_"..group_id)[1]
if tonumber(friend_num) > 0 then
say("{\"success\":false,\"info\":\"分组下有好友，禁止删除！\"}")
    return
end 

--delete mysql
local dsql = "delete from t_social_friend_group where group_id = "..group_id
local dresutl, err = mysql:query(dsql)
if not dresutl then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--delete ssdb
ssdb:zdel("social_friend_group_sorted_"..identity_id.."_"..person_id, group_id)
ssdb:hclear("social_friend_group_"..group_id)

--return
local rr = {}
rr.success = true
rr.info = "删除成功！"

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)