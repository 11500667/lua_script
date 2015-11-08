--[[
记录大学区的点击量[mysql版]
@Author  chenxg
@Date    2015-06-03
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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
local dxq_id = args["dxq_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
local update_sql = "update t_qyjh_dxq set djl_tj = djl_tj+1 where dxq_id="..dxq_id
local dxq_result, err, errno, sqlstate = db:query(update_sql);
if not dxq_result then
	ngx.say("{\"success\":false,\"info\":\"修改大学区点击量失败！\"}");
	return;
end
say("{\"success\":true}")

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
