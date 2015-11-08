--[[
前、后台接口Lua，根据联盟id、模块id查询注册号
@Author feiliming
@Date   2015-2-12
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local league_id = ngx.var.arg_league_id
local module_type = ngx.var.arg_module_type

if not league_id or len(league_id) == 0 
    or not module_type or len(module_type) == 0 then
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

local sql = "SELECT register_id FROM t_wklm_news WHERE league_id = "..quote(league_id).." AND module_type = "..quote(module_type)
local result, err = mysql:query(sql)
if not result then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local rr = {}
rr.success = true
if result and result[1] and result[1].register_id then
    rr.flag = "1"
    rr.regist_id = result[1].register_id
else
    rr.flag = "0"
end
     
say(cjson.encode(rr))
mysql:set_keepalive(0,v_pool_size)