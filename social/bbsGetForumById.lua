--[[
获得版块信息
@Author feiliming
@Date   2015-3-23
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local forum_id = ngx.var.arg_forum_id

if not forum_id or len(forum_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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

--从mysql取
local ssql = "select id,bbs_id,partition_id,name,icon_url,description,sequence from t_social_bbs_forum where id = "..forum_id
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--取版主
local ssql2 = "select forum_id,person_id,identity_id,person_name from t_social_bbs_forum_user where forum_id = "..forum_id.." and flag = 1"
local sresult2, err = mysql:query(ssql2)
local forum_admin_list = {}
if sresult2 and #sresult2 > 0 then
    for i=1, #sresult2 do
        forum_admin_list[#forum_admin_list + 1] = sresult2[i]
    end
end

--return
if sresult and #sresult > 0 then
    local rr = {}
    rr.success = true
    rr.forum_id = sresult[1].id
    rr.partition_id = sresult[1].partition_id
    rr.bbs_id = sresult[1].bbs_id
    rr.name = sresult[1].name
    rr.icon_url = sresult[1].icon_url
    rr.description = sresult[1].description
    rr.sequence = sresult[1].sequence
    rr.forum_admin_list = forum_admin_list
    cjson.encode_empty_table_as_object(false)
    say(cjson.encode(rr))
else
    local rr = {}
    rr.success = false
    rr.info = "未找到版块!"
    say(cjson.encode(rr))
end

--release
mysql:set_keepalive(0,v_pool_size)