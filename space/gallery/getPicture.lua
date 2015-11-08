--[[
获取照片列表
@Author feiliming
@Date   2015-4-24
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
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

local folder_id = args["folder_id"]
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]
if not folder_id or len(folder_id) == 0 or
    not pageNumber or len(pageNumber) == 0 or
    not pageSize or len(pageSize) == 0 then
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

local sqlcount = "SELECT COUNT(*) AS totalRow FROM t_social_gallery_picture WHERE folder_id = "..quote(folder_id)
local totalRow, err = mysql:query(sqlcount)
if not totalRow then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--say(cjson.encode(totalRow))

local totalPage = math.floor((totalRow[1].totalRow + pageSize - 1) / pageSize)
if totalPage > 0 and pageNumber > totalPage then
    pageNumber = totalPage
end
local offset = pageSize*pageNumber-pageSize
local limit = pageSize

--sql
local sql = "SELECT * FROM t_social_gallery_picture WHERE folder_id = "..quote(folder_id).." order by create_time asc LIMIT "..offset..","..pageSize
ngx.log(ngx.ERR,"===="..sql)
local list,err = mysql:query(sql)
if not list then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--say(cjson.encode(list))

--返回值
local returnjson = {}
returnjson.success = true
returnjson.totalRow = totalRow[1].totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
returnjson.picture_list = list

cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

--release
mysql:set_keepalive(0,v_pool_size)