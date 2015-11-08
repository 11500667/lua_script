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

--参数 
local xq_id = args["xq_id"]

--判断参数是否为空
if not xq_id or string.len(xq_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
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

local term_res= db:query("update T_BASE_TERM set SFDQXQ = 1 where XQ_ID = "..xq_id..";update T_BASE_TERM set SFDQXQ = 0 where XQ_ID !="..xq_id..";")


local result = {}
result["success"] = true


cjson.encode_empty_table_as_object(false);
ngx.say(cjson.encode(result))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)