--[[
上传照片
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
local folder_id = args["folder_id"]
local picture_name = args["picture_name"]
local file_id = args["file_id"]
if not person_id or len(person_id) == 0 or
	not identity_id or len(identity_id) == 0 or
	not folder_id or len(folder_id) == 0 or
    not picture_name or len(picture_name) == 0 or
    not file_id or len(file_id) == 0 then
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

--insert
local isql = "insert into t_social_gallery_picture(person_id, identity_id, picture_name, create_time, folder_id, file_id) values ("..
    quote(person_id)..","..quote(identity_id)..","..quote(picture_name)..",now(),"..quote(folder_id)..","..quote(file_id)..")"
ngx.log(ngx.ERR,"===="..isql)
local iresutl, err = mysql:query(isql)
if not iresutl then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--照片数加1
local usql = "UPDATE t_social_gallery_folder SET picture_num = picture_num + 1 WHERE id = "..quote(folder_id)
local uresutl, err = mysql:query(usql)
if not uresutl then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--return
local rr = {}
rr.success = true

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)