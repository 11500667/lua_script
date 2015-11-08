--[[
根据id查询分类
@Author  feiliming
@Date    2015-7-14
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local category_id = ngx.var.arg_category_id
if not category_id or len(category_id) == 0 then
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

local ssql = "SELECT * FROM t_social_notice_category WHERE category_id = "..quote(category_id)
local rt, err = mysql:query(ssql)
if not rt then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--return
local rr = {}
rr.success = true
rr.list = rt

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)