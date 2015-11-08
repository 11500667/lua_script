local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

local bureau_id = tostring(ngx.var.cookie_background_bureau_id)
local person_id = tostring(ngx.var.cookie_background_person_id)

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

local res = db:query("SELECT COUNT(1) AS is_open,IFNULL(regist_id,0) AS regist_id FROM t_djmh_news where bureau_id="..bureau_id.." AND person_id="..person_id)

local is_open = tostring(res[1]["is_open"])
local regist_id = tostring(res[1]["regist_id"])

local result = {}
result["success"] = true
result["is_open"] = is_open
result["regist_id"] = regist_id

ngx.print(cjson.encode(result))
