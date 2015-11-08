#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-05
#描述：后台->学校管理员->设置检查状态
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

if args["status_id"] == nil or args["status_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"status_id参数错误！\"}")
    return
end
local status_id  = tostring(args["status_id"]);


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
local sql_update_status = "update t_resource_check_info set status_id = "..status_id.." where check_id = "..check_id;

local result, err, errno, sqlstate = db:query(sql_update_status)
	if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	  ngx.say("{\"success\":false,\"info\":\"设置检查状态失败！\"}")
	 return
    end
	

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

 ngx.say("{\"success\":true,\"info\":\"设置检查状态成功！\"}")












