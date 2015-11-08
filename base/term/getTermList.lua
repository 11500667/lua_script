--[[
获取学期列表
@Author  chenxg
@Date    2015-05-13
--]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


local cjson = require "cjson"

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

local term_res= db:query("SELECT XQ_ID,XN,XQ,XQMC,SFDQXQ FROM T_BASE_TERM limit 18")
local term_info = term_res

local result = {}
result["success"] = true
result["list"] = term_info

cjson.encode_empty_table_as_object(false);
ngx.say(cjson.encode(result))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)