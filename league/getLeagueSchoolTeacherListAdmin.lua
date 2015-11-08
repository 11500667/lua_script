--[[
后台接口Lua，根据联盟id和学校id分页查询教师
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
local org_id = ngx.var.arg_org_id
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

if not league_id or len(league_id) == 0 
    or not school_id or len(school_id) == 0
	or not pageSize or len(pageSize) == 0 
    or not pageNumber or len(pageNumber) == 0 
    or not org_id or len(org_id) == 0 then
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

--
local teacherlist = {}
local response = ngx.location.capture("/dsideal_yy/person/getPersonBySchool", {
    method = ngx.HTTP_GET,
    args = {
        org_id = org_id,
        school_id = school_id,
        pageNum = pageNumber,
        pageSize = pageSize
    }
})
if response.status == 200 then
    teacherlist = cjson.decode(response.body)
else
    say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end
if not teacherlist.success or teacherlist.success == "false" then
    say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end

--
local pids = {}
for i=1,#teacherlist.list do
    pids[#pids+1] = teacherlist.list[i].person_id
end

--
if pids and #pids > 0 then
    local sql = "SELECT * FROM t_wklm_teacher WHERE league_id = "..quote(league_id).." AND school_id = "..quote(school_id).." AND person_id IN ("..table.concat(pids,",")..")"
    local wteacher = mysql:query(sql)
    for i=1,#teacherlist.list do
        for j=1,#wteacher do
            if teacherlist.list[i].person_id == wteacher[j].person_id then
                teacherlist.list[i].zhaopian_url = wteacher[j].zhaopian_url
                teacherlist.list[i].description = wteacher[j].description
                teacherlist.list[i].set_flag = wteacher[j].set_flag
            end
        end
        if not teacherlist.list[i].zhaopian_url then
            teacherlist.list[i].zhaopian_url = "" 
        end
        if not teacherlist.list[i].description then
            teacherlist.list[i].description = "" 
        end
        if not teacherlist.list[i].set_flag then
            teacherlist.list[i].set_flag = "0" 
        end
    end
end

teacherlist.pageNumber = tonumber(pageNumber)
teacherlist.pageSize = tonumber(pageSize)
teacherlist.totalRow = tonumber(teacherlist.totalRow)

say(cjson.encode(teacherlist))

mysql:set_keepalive(0,v_pool_size)