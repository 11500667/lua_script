#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-13
#描述：修改检查
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

if args["check_name"] == nil or args["check_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_name参数错误！\"}")
    return
end
local check_name  = tostring(args["check_name"]);

if args["check_standard"] == nil or args["check_standard"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_standard参数错误！\"}")
    return
end
local check_standard  = tostring(args["check_standard"]);

if args["start_time"] == nil or args["start_time"] == "" then
    ngx.say("{\"success\":false,\"info\":\"start_time参数错误！\"}")
    return
end
local start_time  = tostring(args["start_time"]);

if args["end_time"] == nil or args["end_time"] == "" then
    ngx.say("{\"success\":false,\"info\":\"end_time参数错误！\"}")
    return
end
local end_time  = tostring(args["end_time"]);



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

local sql_submit = 
"update t_resource_check_info set check_name = '"..check_name.."',check_standard = '"..check_standard.."',start_time = '"..start_time.."',end_time='"..end_time.."' where check_id="..check_id;

ngx.log(ngx.ERR,"===================="..sql_submit.."====================")
local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"设置检查出错！\"}");
	 return
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"设置检查成功\"}")












