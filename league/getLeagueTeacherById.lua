--[[
前台接口Lua，根据联盟id、老师id查学校
@Author feiliming
@Date   2015-2-7
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local ssdblib = require "resty.ssdb"

--get args
local league_id = ngx.var.arg_league_id
local person_id = ngx.var.arg_person_id

if not league_id or len(league_id) == 0 
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

--condition
local condition = "WHERE league_id = "..quote(league_id).." AND person_id = "..quote(person_id)

local sql = "SELECT * FROM t_wklm_teacher t "..condition
--ngx.log(ngx.ERR, "==="..sql)
local teacherlist = mysql:query(sql)
if not teacherlist then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--wk_num
for i=1,#teacherlist do
    local zname = "league_teacher_wknum"
    local key = league_id.."_"..teacherlist[i].person_id
    if stage_id and len(stage_id) > 0 then
        zname = "league_stage_teacher_wknum"
        key = league_id.."_"..stage_id.."_"..teacherlist[i].person_id
    end
    local wk_num = 0
    local znum = ssdb:zget(zname, key)
    if znum and znum[1] and len(znum[1]) > 0 and znum[1] ~= "ok" and znum[1] ~= "not_found" then
        wk_num = znum[1]
    end
    teacherlist[i].wk_num = wk_num
    --if not teacherlist[i].description then
    --   teacherlist[i].description = ""
    --end
    local aService = require "space.services.PersonAndOrgBaseInfoService"
    local rt = aService:getPersonBaseInfo("5", teacherlist[i].person_id)
    teacherlist[i].zhaopian_url = rt and rt[1] and rt[1].avatar_fileid or ""
    teacherlist[i].description = rt and rt[1] and rt[1].person_description or ""    
end

local rr = {}
rr.success = true
rr.list = teacherlist
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

mysql:set_keepalive(0,v_pool_size)