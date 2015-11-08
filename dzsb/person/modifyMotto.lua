local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误\"}")
    return
end

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误\"}")
    return
end

if args["motto"] == nil or args["motto"] == "" then
    ngx.say("{\"success\":false,\"info\":\"motto参数错误\"}")
    return
end

local person_id = args["person_id"]
local identity_id = args["identity_id"]
local motto = args["motto"]

--连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
    ngx.log(ngx.ERR, err);
    return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 
}

local sql = "";
if identity_id == "5" then
	sql = "UPDATE t_base_person SET MOTTO = '"..motto.."' WHERE PERSON_ID = "..person_id.." AND IDENTITY_ID = 5";
else
	sql = "UPDATE t_base_student SET MOTTO = '"..motto.."' WHERE student_id = "..person_id;
end

db:query(sql);
	
ngx.say("{\"success\":true}");

ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end