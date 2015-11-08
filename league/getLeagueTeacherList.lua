--[[
前台接口Lua，根据联盟id、学段id查学校
@Author feiliming
@Date   2015-2-6
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
local stage_id = ngx.var.arg_stage_id
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

if not league_id or len(league_id) == 0 
    or not pageSize or len(pageSize) == 0 
    or not pageNumber or len(pageNumber) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

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
local condition = "WHERE league_id = "..quote(league_id)
if stage_id and len(stage_id) > 0 then
	condition = "WHERE league_id = "..quote(league_id).." AND stage_id = "..quote(stage_id)
end

local sqlcount = "SELECT count(*) as totalRow FROM t_wklm_teacher t "..condition
local totalRow_t = mysql:query(sqlcount)
if not totalRow_t then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local totalRow = totalRow_t[1].totalRow
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

--page
local offset = pageSize*pageNumber - pageSize
local limit = pageSize
local sql = "SELECT * FROM t_wklm_teacher t "..condition.." ORDER BY sequence DESC LIMIT "..offset..", "..pageSize
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
local personIds = {}
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
    --    teacherlist[i].description = ""
    --else
    --   teacherlist[i].description = ngx.decode_base64(teacherlist[i].description)
    --end
    table.insert(personIds, teacherlist[i].person_id)
end
--调用空间接口取基本信息
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfo("5", unpack(personIds))
for i=1,#teacherlist do
    for _, v in ipairs(rt) do
        if tostring(teacherlist[i].person_id) == tostring(v.personId) then
            teacherlist[i].zhaopian_url = v and v.avatar_fileid or ""
            teacherlist[i].description = v and v.person_description or ""
            break
        end
    end
end

local rr = {}
rr.success = true
rr.totalRow = totalRow
rr.totalPage = totalPage
rr.pageNumber = pageNumber
rr.pageSize = pageSize
rr.list = teacherlist
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

mysql:set_keepalive(0,v_pool_size)