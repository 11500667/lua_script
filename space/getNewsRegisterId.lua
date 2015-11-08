--[[
查询注册号
@Author feiliming
@Date   2015-4-23
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local a_id = ngx.var.arg_a_id
local a_identity_id = ngx.var.arg_a_identity_id

if not a_id or len(a_id) == 0 
    or not a_identity_id or len(a_identity_id) == 0 then
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

local sql = "SELECT register_id FROM t_social_news_register WHERE a_id = "..quote(a_id).." AND a_identity_id = "..quote(a_identity_id)
local result, err = mysql:query(sql)
if not result then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local rr = {}
rr.success = true
if result and result[1] and result[1].register_id then
    rr.flag = 1
    rr.regist_id = result[1].register_id
else
    rr.flag = 0
end
     
say(cjson.encode(rr))
mysql:set_keepalive(0,v_pool_size)