--[[
根据区域ID判断该区域是否开通区域均衡
@Author  chenxg
@Date    2015-02-06
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

--获得get请求参数
--local person_id = ngx.var.arg_person_id
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--say(#ab) --返回1, 即使键值不存在table里也存了一个空串"", 类型为string, cjson.encode()后也是string, 所以可以用string.len()
local returnjson = {}
local person_sql = "select person_id,identity_id from t_base_delete_person where org_id !=0"
local result = mysql_db:query(person_sql)
if #result>=1 then
	for i = 1,#result,1 do
		cache:del("person_"..result[i].person_id.."_"..result[i].identity_id)
	end
end

local login_sql = "select login_name from t_base_delete_loginperson where person_id not in(select person_id from t_base_delete_person where org_id=0)"
local result2 = mysql_db:query(login_sql)
if #result2>=1 then
	for i = 1,#result2,1 do
		cache:del("login_"..result2[i].login_name)
	end
end
returnjson.success=true

--return

say("callback("..cjson.encode(returnjson)..");")

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)