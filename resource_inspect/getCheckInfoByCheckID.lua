#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-10
#描述：获得检查的详细信息
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

if args["check_id"] == nil or args["check_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_id参数错误！\"}")
    return
end
local check_id  = tostring(args["check_id"]);


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
local sql_check_info = "SELECT check_name,check_standard,start_time,end_time FROM t_resource_check_info WHERE CHECK_id ="..check_id;

local result_check, err, errno, sqlstate = db:query(sql_check_info)
	if not result_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};

resultJson.success = true;
resultJson.check_name = result_check[1]["check_name"];
resultJson.check_standard =  result_check[1]["check_standard"];
resultJson.start_time = result_check[1]["start_time"];
resultJson.end_time = result_check[1]["end_time"];


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












