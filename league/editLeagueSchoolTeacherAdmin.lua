--[[
后台接口Lua，编辑教师
@Author feiliming
@Date   2015-2-4
--]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
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

--获得请求参数
local league_id = args["league_id"]
local school_id = args["school_id"]
local person_id = args["person_id"]
local person_name = args["person_name"]
local zhaopian_url = args["zhaopian_url"]
local description = args["description"]
local stage_id = args["stage_id"]
local stage_name = args["stage_name"]
local subject_id = args["subject_id"]
local subject_name = args["subject_name"]

if not league_id or len(league_id) == 0
	or not school_id or len(school_id) == 0
	or not person_id or len(person_id) == 0
	or not zhaopian_url or len(zhaopian_url) == 0
    or not person_name or len(person_name) == 0
    or not stage_id or len(stage_id) == 0
    or not stage_name or len(stage_name) == 0
    or not subject_id or len(subject_id) == 0
    or not subject_name or len(subject_name) == 0
	or not description then
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

local set_flag = 0
if description and len(description) > 0 then
	set_flag = 1
end

local selectsql = "SELECT id FROM t_wklm_teacher t WHERE league_id = "..quote(league_id).." AND school_id = "..quote(school_id).." AND person_id = "..quote(person_id)
local sr, err = mysql:query(selectsql)
if not sr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if sr and #sr > 0 then
    local sql = "UPDATE t_wklm_teacher SET zhaopian_url = "..quote(zhaopian_url)..", description = "..quote(description)..", set_flag = "..set_flag.." WHERE league_id = "..quote(league_id).." AND school_id = "..quote(school_id).." AND person_id = "..quote(person_id)
    local ok, err = mysql:query(sql)
    if not ok then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
else
    local ssdb = ssdblib:new()
    local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
    if not ok then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    local id = ssdb:incr("t_wklm_teacher_pk", 1)
    local sql = "INSERT INTO t_wklm_teacher(id, league_id, school_id, person_id, person_name, stage_id, stage_name, subject_id, subject_name, zhaopian_url, description, set_flag) VALUES("..
        id[1]..","..league_id..","..school_id..","..person_id..","..quote(person_name)..","..stage_id..","..quote(stage_name)..","..subject_id..","..quote(subject_name)..","..quote(zhaopian_url)..","..quote(description)..","..set_flag..")"
    local ok, err = mysql:query(sql)
    if not ok then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
end

say("{\"success\":true,\"info\":\"修改成功！\"}")

mysql:set_keepalive(0,v_pool_size)