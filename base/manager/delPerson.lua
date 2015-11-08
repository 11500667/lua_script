#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-15
#描述：删除区县或者校管理员
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

if args["unit_id"] == nil or args["unit_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"unit_id参数错误！\"}")
    return
end
local unit_id  = tostring(args["unit_id"]);


if args["unit_type"] == nil or args["unit_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"unit_type参数错误！\"}")
    return
end
local unit_type  = tostring(args["unit_type"]);



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

--local sql_submit = "update t_base_maneger SET b_use = 0 where unit_id = "..unit_id..",unit_type="..unit_type..",person_id = "..person_id..",identity_id = "..identity_id;
local sql_submit = "update t_base_maneger SET b_use = 0 where  unit_type = "..unit_type.." and unit_id = "..unit_id.." and person_id = "..person_id.." and identity_id = "..identity_id;

ngx.log(ngx.ERR,"=============="..sql_submit)
local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"删除区县管理员失败！\"}");
	 return
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"删除区县管理员成功！\"}")

