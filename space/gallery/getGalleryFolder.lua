--[[
获取相册列表
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

local person_id = args["person_id"]
local identity_id = args["identity_id"]
local is_private = args["is_private"]
if not person_id or len(person_id) == 0 or
    not identity_id or len(identity_id) == 0 then
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

--sql
local sql = "SELECT * FROM t_social_gallery_folder t WHERE person_id = "..quote(person_id).." and identity_id = "..quote(identity_id).." order by create_time asc "
if is_private and len(is_private) > 0 then
    sql = sql.." and is_private = "..quote(is_private)
end
ngx.log(ngx.ERR,"====="..sql)
--select
local list,err = mysql:query(sql)
if not list then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end 

--return
local rr = {}
rr.success = true
rr.folder_list = list

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)