--[[
后台接口Lua，根据联盟id分页查询学校
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

local sqlcount = "SELECT COUNT(*) AS totalRow FROM t_wklm_school WHERE league_id = "..quote(league_id)
local totalRow = mysql:query(sqlcount)
--say(cjson.encode(totalRow))

local totalPage = math.floor((totalRow[1].totalRow + pageSize - 1) / pageSize)
if pageNumber > totalPage then
	pageNumber = totalPage
end
local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local sqllist = "SELECT * FROM t_wklm_school WHERE league_id = "..quote(league_id).." ORDER BY sequence DESC LIMIT "..offset..","..pageSize
local schoollist = mysql:query(sqllist)
--say(cjson.encode(schoollist))

--返回值
local returnjson = {}
returnjson.success = true
returnjson.totalRow = totalRow[1].totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
returnjson.list = schoollist
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

mysql:set_keepalive(0,v_pool_size)
