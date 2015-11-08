--[[
记录活动的评论数[mysql版]
@Author  chenxg
@Date    2015-06-04
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

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
--参数 
local hd_id = args["hd_id"]

--判断参数是否为空
if not hd_id or string.len(hd_id) == 0
   then
    say("{\"success\":false,\"info\":\"hd_id参数错误！\"}")
    return
end

--连接mysql数据库
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
local update_sql = "update t_qyjh_hd set pls_tj = pls_tj+1 where hd_id = "..hd_id
local tea_count_result, err, errno, sqlstate = db:query(update_sql);
--ngx.log(ngx.ERR,"cxg_log update_sql===========>"..tea_count_result.."**"..sqlstate.."====");
say("{\"success\":true,\"pls\":\"0\"}")

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
