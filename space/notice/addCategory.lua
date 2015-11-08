--[[
添加分类
@Author  feiliming
@Date    2015-7-14
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

--post args
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

local register_id = args["register_id"]
local category_name = args["category_name"]
local parent_id = args["parent_id"]
if not register_id or len(register_id) == 0 or
    not category_name or len(category_name) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

if not parent_id or len(parent_id) == 0 then
    parent_id = "-1"
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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

local isql = "INSERT INTO t_social_notice_category(register_id, category_name, create_time, parent_id, b_delete)"..
" VALUES ("..quote(register_id)..", "..quote(category_name)..", NOW(), "..quote(parent_id)..", 0) "

local ir, err = mysql:query(isql)
if not ir then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local category_id = ir.insert_id

local category = {}
category.category_id = category_id
category.category_name = category_name
category.parent_id = parent_id
local hr, err = ssdb:multi_hset("social_notice_category_"..category_id, category)
if not hr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--return
local rr = {}
rr.success = true
rr.category_id = category_id

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)