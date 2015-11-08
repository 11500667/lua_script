local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

ngx.log(ngx.ERR,"@@@@@@@@@".."二次备课校验登录".."@@@@@@@@@")

local cjson = require "cjson"

--先判断参数是否正确
if tostring(args["person_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id 参数错误！\"}")    
    return
end

--获取用户名参数
local person_id = tostring(args["person_id"])
local usertype = tostring(args["usertype"])
	
--获取登录来源信息和mac信息
--1:teach 2:office
local quote = ngx.quote_sql_str
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

--查询数据库，对比该mac地址是否已经在列表中
--查询数据库，获取已经登录过的机器列表
local countSql = "select host_mac from t_base_person_loginrecord where person_id="..person_id.." and system_type="..usertype..";";
local results, err, errno, sqlstate = db:query(countSql);
if not results then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end
local allowsum = 3;
local maslist = {}
local nowsum = #results
for i=1,#results,1 do
	maslist[i] = results[i]["host_mac"]
end

local returnjson = {}
returnjson.success = true
returnjson.allowsum = allowsum
returnjson.nowsum = nowsum
returnjson.maslist = maslist
ngx.say(cjson.encode(returnjson))
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

--陈续刚20150506添加
   
