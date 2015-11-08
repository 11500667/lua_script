--[[
后台接口Lua，根据联盟id和学校id查询学校
@Author feiliming
@Date   2015-2-4
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local league_id = ngx.var.arg_league_id
local school_id = ngx.var.arg_school_id

if not league_id or len(league_id) == 0 
	or not school_id or len(school_id) == 0 then
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

local sql = "SELECT * FROM t_wklm_school t WHERE league_id = "..quote(league_id).." AND school_id = "..quote(school_id)
local list = mysql:query(sql)

if not list or #list == 0 then
    say("{\"success\":false,\"info\":\"未找到学校！\"}")
    return
end 

local school = {}
school.id = list[1].id
school.league_id = list[1].league_id
school.school_id = list[1].school_id
school.school_name = list[1].school_name
school.school_type = list[1].school_type
school.xiaohui_url = list[1].xiaohui_url
if not school.xiaohui_url then
    school.xiaohui_url = ""
end
school.fengguang_url = list[1].fengguang_url
if not school.fengguang_url then
    school.fengguang_url = ""
end
school.description = list[1].description
if not school.description then
    school.description = ""
end
school.sequence = list[1].sequence
school.set_flag = list[1].set_flag

local returnjson = {}
returnjson.success = true
returnjson.school = school
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

mysql:set_keepalive(0,v_pool_size)