local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--regist_id
if args["regist_id"] == nil or args["regist_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
    return
end
local regist_id = args["regist_id"]

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

ngx.log(ngx.ERR,"@@@@@@@@@".."INSERT INTO t_djmh_news (regist_id,bureau_id,person_id) VALUES ("..regist_id..","..bureau_id..","..person_id..")".."@@@@@@@@@")

db:query("INSERT INTO t_djmh_news (regist_id,bureau_id,person_id) VALUES ("..regist_id..","..bureau_id..","..person_id..")")

local result = {}
result["success"] = true

ngx.print(cjson.encode(result))
