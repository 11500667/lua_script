--[[
根据区域ID判断该区域是否开通区域均衡[mysql版]
@Author  chenxg
@Date    2015-06-01
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

--获得get请求参数
--local person_id = ngx.var.arg_person_id
local region_id = ngx.var.arg_region_id
if not region_id or string.len(region_id) == 0 then
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
--判断region_id是否存在, 存在则返回qyjh_id,b_use,b_open,name
--判断是否已经开通
local querySql = "select b_open,b_use from t_qyjh_qyjhs where qyjh_id= "..region_id;
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
local returnjson = {}
if #result == 0 then
	returnjson.success = false
else
	if result[1]["b_use"] == 0 then
		returnjson.success = false
	else
		returnjson.success=true
	end

end

--return
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)