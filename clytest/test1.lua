#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-29
#描述：
]]
--1.获取参数的方法
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--2.获取参数id，并判断参数书否正确
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end

local id = args["id"];
--获取参数student_name，并判断参数书否正确
if args["student_name"] == nil or args["student_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_name参数错误！\"}")
    return
end

local student_name = args["student_name"];

--获取参数b_use，并判断参数书否正确
if args["b_use"] == nil or args["b_use"] == "" then
    ngx.say("{\"success\":false,\"info\":\"b_use参数错误！\"}")
    return
end

local b_use = args["b_use"];
--获取参数bureau_id，并判断参数书否正确
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
    return
end

local bureau_id = args["bureau_id"];
--获取参数class_id，并判断参数书否正确
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误！\"}")
    return
end

local class_id = args["class_id"];
--获取参数check_massage，并判断参数书否正确
if args["check_massage"] == nil or args["check_massage"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_massage参数错误！\"}")
    return
end

local check_massage = args["check_massage"];


--3.链接数据库
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
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end
--4.链接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--5.链接ssdb服务器
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--写入数据库
local student_res = "INSERT INTO t_base_student(STUDENT_ID,STUDENT_NAME,B_USE,BUREAU_ID,CLASS_ID,CHECK_MASSAGE) VALUES ("..id..",'"..student_name.."',"..b_use..","..bureau_id..","..class_id..","..check_massage..");";
local students_res, err, errno, sqlstate = db:query(student_res);
if not students_res then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end






--6.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 7.将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

--8.放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
















