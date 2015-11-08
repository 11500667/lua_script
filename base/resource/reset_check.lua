#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-06-01
#描述：重置审核状态
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

local myts = require "resty.TS";
local ts =  myts.getTs();

--传参数
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int  = tostring(args["resource_id_int"]);

if args["check_status"] == nil or args["check_status"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_status参数错误！\"}")
    return
end
local check_status  = tostring(args["check_status"]);

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

local sql_check = "UPDATE t_resource_base set check_status = 2 WHERE resource_id_int = "..resource_id_int;

local sql_info_check = "UPDATE t_resource_info SET release_status = 4,group_id=0,update_ts = "..ts.." WHERE GROUP_ID = 1 AND RESOURCE_ID_INT = "..resource_id_int;

db:query(sql_check);
if check_status == "1" then
 db:query(sql_info_check);
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"操作成功！\"}")
