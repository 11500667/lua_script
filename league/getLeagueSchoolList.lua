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
local region_id = ngx.var.arg_region_id
local region_name = ngx.unescape_uri(ngx.var.arg_region_name)
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
    if stage_id == "4" then
        condition = condition.." AND school_type in (1,5,6)"
    elseif stage_id == "5" then
        condition = condition.." AND school_type in (2,4,5,6)"
    elseif stage_id == "6" then
        condition = condition.." AND school_type in (3,4,6)"
    end
end
if region_id and len(region_id) > 0 then
    condition = condition.." AND region_id = "..region_id
end

local sqlcount = "SELECT count(*) as totalRow FROM t_wklm_school t "..condition
local totalRow_t, err = mysql:query(sqlcount)
if not totalRow_t then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local totalRow = totalRow_t[1].totalRow
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

--page
local offset = pageSize*pageNumber - pageSize
local limit = pageSize
local sql = "SELECT * FROM t_wklm_school t "..condition.." ORDER BY sequence DESC LIMIT "..offset..", "..pageSize
local schoollist = mysql:query(sql)
if not schoollist then
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
local schoolIds = {}
for i=1,#schoollist do
    local zname = "league_school_wknum"
    local key = league_id.."_"..schoollist[i].school_id
    if stage_id and len(stage_id) > 0 then
        zname = "league_stage_school_wknum"
        key = league_id.."_"..stage_id.."_"..schoollist[i].school_id
    end
    local wk_num = 0
    local znum = ssdb:zget(zname, key)
    if znum and znum[1] and len(znum[1]) > 0 and znum[1] ~= "ok" and znum[1] ~= "not_found" then
        wk_num = znum[1]
    end
    schoollist[i].wk_num = wk_num
    --if not schoollist[i].description then
    --    schoollist[i].description = ""
    --else
    --    schoollist[i].description = ngx.decode_base64(schoollist[i].description)
    --end
    table.insert(schoolIds, schoollist[i].school_id)
end
--调用空间接口取基本信息
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getOrgBaseInfo("104", unpack(schoolIds))
for i=1,#schoollist do
    for _, v in ipairs(rt) do
        if tostring(schoollist[i].school_id) == tostring(v.orgId) then
            schoollist[i].xiaohui_url = v and v.org_logo_fileid or ""
            schoollist[i].fengguang_url = v and v.org_scenery_fileid or ""
            schoollist[i].description = v and v.org_description or ""
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
rr.list = schoollist
if region_id and len(region_id) > 0 then
    rr.region_id = region_id
end
if region_name and len(region_name) > 0 then
    rr.region_name = region_name
end
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

mysql:set_keepalive(0,v_pool_size)