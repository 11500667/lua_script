-- 验证图片是否删除.
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/6/3
-- Time: 10:21
-- To change this template use File | Settings | File Templates.
--
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

local file_ids = args["file_ids"]
if not file_ids or len(file_ids) == 0 then
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

local t_ids = Split(file_ids,",")
local t_sqls = {}
for i=1,#t_ids do
    local fid = quote(t_ids[i])
    table.insert(t_sqls,fid)
end
local str = table.concat(t_sqls,",")
local DBUtil = require "common.DBUtil";
local checkSql = "SELECT file_id FROM T_SOCIAL_GALLERY_PICTURE T WHERE T.FILE_ID IN ("..str..")";
local ids = DBUtil:querySingleSql(checkSql);

local result = {}
if ids then
    for i=1,#ids do
        table.insert(result,ids[i]['file_id'])
    end
end

local rr = {}
rr.success = true
rr.file_ids = result
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))
--release
mysql:set_keepalive(0,v_pool_size)