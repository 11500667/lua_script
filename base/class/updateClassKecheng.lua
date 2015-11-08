local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误\"}")
    return
end

if args["xq_id"] == nil or args["xq_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"xq_id参数错误\"}")
    return
end

if args["pointname"] == nil or args["pointname"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pointname参数错误\"}")
    return
end

if args["weekday"] == nil or args["weekday"] == "" then
    ngx.say("{\"success\":false,\"info\":\"weekday参数错误\"}")
    return
end

if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误\"}")
    return
end

if args["subject_name"] == nil or args["subject_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_name参数错误\"}")
    return
end


local class_id = args["class_id"];
local xq_id = args["xq_id"];
local pointname = args["pointname"];
local weekday = args["weekday"];
local subject_id = args["subject_id"];
local subject_name = args["subject_name"];



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


local sql = "select id from t_base_kechengbiao where class_id = "..class_id.." and xq_id ="..xq_id.." and weekday="..weekday.." and pointname ="..pointname;

local is_id = db:query(sql);
   
local update_sql = "";

if #is_id>0 then 
    update_sql = "update t_base_kechengbiao set subject_id = "..subject_id..",subject_name = '"..subject_name.."' where class_id = "..class_id.." and xq_id ="..xq_id.." and weekday="..weekday.." and pointname ="..pointname;
else
    update_sql = "insert into t_base_kechengbiao(class_id,xq_id,weekday,pointname,subject_id,subject_name) values("..class_id..","..xq_id..","..weekday..","..pointname..","..subject_id..",'"..subject_name.."')";
end

ngx.log(ngx.ERR,"888888888888888888888888888888888"..update_sql)
local results, err, errno, sqlstate = db:query(update_sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"操作数据错误！\"}");
    return
end

ngx.say("{\"success\":true,\"info\":\"操作成功！\"}");

ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
