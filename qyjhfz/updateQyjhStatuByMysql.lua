--[[
启用、停用区域均衡[mysql版]
@Author  chenxg
@Date    2015-06-01
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

local region_id = args["region_id"]
local b_use = args["b_use"]
if not region_id or string.len(region_id) == 0  or not b_use or string.len(b_use) == 0 then
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

--判断是否已经开通
local querySql = "select b_open from t_qyjh_qyjhs where qyjh_id= "..region_id;
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
local returnjson = {}
if result and result[1]["b_open"] == 0 then
	say("{\"success\":false,\"info\":\"尚未开通！\"}")
	return
end

--更新

local updateSql = "update t_qyjh_qyjhs set b_use="..b_use.." where qyjh_id= "..region_id;
local results, err, errno, sqlstate = db:query(updateSql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"修改区域均衡失败！\"}");
    return;
end
--return
say("{\"success\":true,\"b_use\":\""..b_use.."\"}")

--mysql放回连接池
db:set_keepalive(0,v_pool_size)