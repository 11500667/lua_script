--[[
后台接口Lua，根据联盟id和学校id和person_id查询教师
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
local person_id = ngx.var.arg_person_id

if not league_id or len(league_id) == 0 
	or not school_id or len(school_id) == 0 
    or not person_id or len(person_id) == 0 then
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

local sql = "SELECT * FROM t_wklm_teacher t WHERE league_id = "..quote(league_id).." AND school_id = "..quote(school_id).." AND person_id = "..quote(person_id)
local list = mysql:query(sql)
if not list then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if list and #list == 0 then
    local rr = {}
    rr.success = true
    rr.exist = false
    say(cjson.encode(rr))
    return
end 

local teacher = {}
teacher.id = list[1].id
teacher.league_id = list[1].league_id
teacher.school_id = list[1].school_id
teacher.person_id = list[1].person_id
teacher.person_name = list[1].person_name
teacher.stage_id = list[1].stage_id
teacher.stage_name = list[1].stage_name
teacher.subject_id = list[1].subject_id
teacher.subject_name = list[1].subject_name
teacher.zhaopian_url = list[1].zhaopian_url
teacher.description = list[1].description
teacher.set_flag = list[1].set_flag
if not teacher.zhaopian_url then
    teacher.zhaopian_url = ""
end
if not teacher.description then
    teacher.description = ""
end


local returnjson = {}
returnjson.success = true
returnjson.exist = true
returnjson.teacher = teacher
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

mysql:set_keepalive(0,v_pool_size)