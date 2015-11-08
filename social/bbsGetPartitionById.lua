--[[
获得分区信息
@Author feiliming
@Date   2015-3-23
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local partition_id = ngx.var.arg_partition_id

if not partition_id or len(partition_id) == 0 then
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
local ssql = "select id,bbs_id,name,sequence from t_social_bbs_partition where id = "..partition_id
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--return
if sresult and #sresult > 0 then
    local rr = {}
    rr.success = true
    rr.partition_id = sresult[1].id
    rr.bbs_id = sresult[1].bbs_id
    rr.name = sresult[1].name
    rr.sequence = sresult[1].sequence
    cjson.encode_empty_table_as_object(false)
    say(cjson.encode(rr))
else
    local rr = {}
    rr.success = false
    rr.info = "未找到分区!"
    say(cjson.encode(rr))
end

--release
mysql:set_keepalive(0,v_pool_size)