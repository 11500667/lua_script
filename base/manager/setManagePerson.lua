#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-15
#描述：设置人员为区县管理员或者是学校管理员
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

if args["person_name"] == nil or args["person_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_name参数错误！\"}")
    return
end
local person_name  = tostring(args["person_name"]);

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

if args["unit_name"] == nil or args["unit_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"unit_name参数错误！\"}")
    return
end
local unit_name  = tostring(args["unit_name"]);

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

--判断一下用户是否是区县管理员或者是学校管理员
local sel_submit = "SELECT COUNT(*) as count FROM t_base_maneger WHERE person_id = "..person_id.." AND unit_id = "..unit_id.." and b_use = 1 and unit_type = "..unit_type.." and identity_id = "..identity_id;

local count = db:query(sel_submit);

if tonumber(count[1]["count"]) >0 then
ngx.say("{\"success\":false,\"info\":\"该人员已经是管理员！\"}")
else
local create_time = ngx.localtime();
local sql_submit = "INSERT into t_base_maneger(unit_id,unit_type,person_id,identity_id,person_name,unit_name,create_time,b_use) values("..unit_id..","..unit_type..","..person_id..","..identity_id..",'"..person_name.."','"..unit_name.."','"..create_time.."',1)";

local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"设置区县管理员！\"}");
	 return
end
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end 
ngx.say("{\"success\":true,\"info\":\"设置区县管理员\"}")

end
