#ngx.header.content_type = "text/plain;charset=utf-8"

--[[
#曹洪念 2015-08-13
#描述：获取学生出勤情况
#参数：学生id 教师id 当前时间curTime 2015-08-13
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

--2.获得参数
--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end
local student_id = args["student_id"]

--获得教师id
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
local teacher_id = args["teacher_id"]

--获得当前时间
if args["curTime"] == nil or args["curTime"] == "" then
    ngx.say("{\"success\":false,\"info\":\"curTime参数错误！\"}")
    return
end
local curTime = args["curTime"]

--3.连接数据库
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
		ngx.print("{\"success\":false,\"info\":\"连接数据库失败！\"}")
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 连接数据库失败!");
		return false;
	end
    
--4.查询数据
local sql = "SELECT COUNT(1) AS cont FROM T_BAG_CQJSTW WHERE TYPE_ID=1 AND STUDENT_ID="..student_id.." AND TEACHER_ID="..teacher_id.." AND date(TIME)='"..curTime.."'"
ngx.log(ngx.ERR,"##########",sql)

local list, err, errno, sqlstate = db:query(sql);
if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

local result = {} 
result["success"] = true

if list[1]["cont"] > "0"
then
result["isTurnOut"] = "1"
else
result["isTurnOut"] = "0"
end

-- 5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 6.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJson = cjson.encode(result);

-- 7.输出json串到页面
ngx.say(resultJson);

