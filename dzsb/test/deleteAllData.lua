local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误\"}")
    return
end
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误\"}")
    return
end
--参数
local resource_id = args["resource_id"];
local class_id = args["class_id"];

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

local sql1 = "UPDATE t_bag_sjstate SET is_exam = 0 WHERE resource_id = '"..resource_id.."' AND class_id = "..class_id;
db:query(sql1);
local sql2 = "UPDATE t_resource_sendstudent SET state_id = 1 WHERE resource_id = '"..resource_id.."' AND class_id = "..class_id;
db:query(sql2);
local sql3 = "DELETE FROM t_bag_ststuinfo WHERE resource_id='"..resource_id.."' AND class_id = "..class_id;
db:query(sql3);
ngx.say("{\"success\":true}")
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
