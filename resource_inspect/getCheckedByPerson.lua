#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-05
#描述：获得检查人员可以检查哪些检查
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--传参数
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id  = tostring(args["person_id"]);

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);


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


--拼接sql语句
local sql_check = "SELECT t1.check_id,t2.check_name FROM t_resource_check_person_subject AS t1 INNER JOIN t_resource_check_info as t2 ON t1.check_id = t2.check_id WHERE b_use = 1 and status_id = 1 and person_id = "..person_id.." AND identity_id = "..identity_id.." GROUP BY t1.check_id";

local result_check, err, errno, sqlstate = db:query(sql_check)
	if not result_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};
local person_check = {};
for i=1,#result_check do
   local tab={};
   tab.check_id = result_check[i]["check_id"];
   tab.check_name = result_check[i]["check_name"];
   person_check[i] = tab;
end
resultJson.success = true;
resultJson.check_list = person_check;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);












