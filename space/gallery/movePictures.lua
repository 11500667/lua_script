--[[
移动照片
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

local picture_ids = args["picture_ids"]
local from_folder_id = args["from_folder_id"]
local to_folder_id = args["to_folder_id"]
if not picture_ids or len(picture_ids) == 0 or
	not from_folder_id or len(from_folder_id) == 0 or
    not to_folder_id or len(to_folder_id) == 0 then
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

local t_ids = Split(picture_ids,",")
local t_sqls = {}
for i=1,#t_ids do
    local pid = t_ids[i]
    if pid and len(pid) > 0 then
        local dsql = "update t_social_gallery_picture set folder_id = "..quote(to_folder_id).." where id = "..quote(pid)..";"
        table.insert(t_sqls,dsql)
    end
end
--从照片数-n
local usql = "UPDATE t_social_gallery_folder SET picture_num = picture_num - "..#t_sqls.." WHERE id = "..quote(from_folder_id)..";"
table.insert(t_sqls,usql)
--照片数+n
local usql1 = "UPDATE t_social_gallery_folder SET picture_num = picture_num + "..(#t_sqls-1).." WHERE id = "..quote(to_folder_id)..";"
table.insert(t_sqls,usql1)

local DBUtil = require "common.DBUtil";
local dresult = DBUtil:batchExecuteSqlInTx(t_sqls, 1000)

--[[照片数
if dresult then
    --从照片数-n
    local usql = "UPDATE t_social_gallery_folder SET picture_num = picture_num - "..#t_sqls.." WHERE id = "..quote(from_folder_id)
    local uresutl, err = mysql:query(usql)
    if not uresutl then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --照片数+n
    local usql1 = "UPDATE t_social_gallery_folder SET picture_num = picture_num + "..#t_sqls.." WHERE id = "..quote(to_folder_id)
    local uresutl1, err = mysql:query(usql1)
    if not uresutl1 then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
end
]]

--return
local rr = {}
rr.success = true
if not dresult then
    rr.success = false
    rr.info = "移动失败！"
end

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)