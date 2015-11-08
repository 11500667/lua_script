--[[
后台接口Lua，编辑学校
@Author feiliming
@Date   2015-2-4
--]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

local cjson = require "cjson"
local mysqllib = require "resty.mysql"

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
local xiaohui_url = args["xiaohui_url"]
local fengguang_url = args["fengguang_url"]
local description = args["description"]

if not league_id or len(league_id) == 0
	or not school_id or len(school_id) == 0
	or not xiaohui_url or len(xiaohui_url) == 0
	or not fengguang_url or len(fengguang_url) == 0
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

local sql = "UPDATE t_wklm_school SET xiaohui_url = "..quote(xiaohui_url)..", fengguang_url = "..quote(fengguang_url)..", description = "..quote(description)..", set_flag = "..set_flag.." WHERE league_id = "..quote(league_id).." AND school_id = "..quote(school_id)
local ok, err = mysql:query(sql)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

say("{\"success\":true,\"info\":\"修改成功！\"}")

mysql:set_keepalive(0,v_pool_size)