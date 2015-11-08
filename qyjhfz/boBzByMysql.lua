--[[
判断当前用户是否为版块的版主[mysql版]
@Author  chenxg
@Date    2015-06-18
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--获得get请求参数
local person_id = ngx.var.arg_person_id
local bbs_id = ngx.var.arg_bbs_id
if not person_id or string.len(person_id) == 0 or not bbs_id or string.len(bbs_id) == 0
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

local returnjson ={}
returnjson.success = true

local query_sql = "select bbs_pk from t_qyjh_bbs where person_id="..person_id.." and bbs_pk = "..bbs_id
local has_result, err, errno, sqlstate = db:query(query_sql);
if not has_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败55！\"}");
	return;
end
if #has_result>0 then
	returnjson.is_bz = true
else
	returnjson.is_bz = false
end--return
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)