--[[
联盟列表
@Author feiliming
@Date   2015-1-19
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--get args
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

if not pageSize or len(pageSize) == 0 
    or not pageNumber or len(pageNumber) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--paging
local t_totalRow = ssdb:zcount("league_leagues_sorted", "", "")
local totalRow = t_totalRow[1]
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
if pageNumber > totalPage then
    pageNumber = totalPage
end
local offset = pageSize*pageNumber - pageSize
local limit = pageSize

--zrange
local res = ssdb:zrange("league_leagues_sorted", offset, limit)
local lids = {}
if res and res[1] and res[1] ~= "ok" then
    for i=1,#res,2 do
        table.insert(lids, res[i])
    end
end

--multi_hget
local list = {}
local leagues 
if lids and #lids > 0 then
    leagues = ssdb:multi_hget("league_leagues", unpack(lids))
end
if leagues and leagues[1] and leagues[1] ~= "ok" then
    for i=1,#leagues,2 do
        local league = cjson.decode(leagues[i+1])
        table.insert(list, league)
    end
end

--return result
local rr = {}
rr.success = true
rr.totalRow = totalRow
rr.totalPage = totalPage
rr.pageNumber = pageNumber
rr.pageSize = pageSize
rr.list = list
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

ssdb:set_keepalive(0,v_pool_size)