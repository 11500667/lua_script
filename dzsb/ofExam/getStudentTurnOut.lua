#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-12
#描述：获取班级关于某次考试的列表
 参数：teacher_id：老师的id student_id：学生id startDate：开始日期 endDate：结束日期
 涉及到的表：t_bag_cqjstw
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

--2.获得参数方法
--获得老师id
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}");
    return;
end
local teacher_id = ngx.quote_sql_str(tostring(args["teacher_id"]));

--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}");
    return;
end
local student_id = ngx.quote_sql_str(tostring(args["student_id"]));

--获得开始日期
if args["startDate"] == nil or args["startDate"] == "" then
    ngx.say("{\"success\":false,\"info\":\"startDate参数错误！\"}");
    return;
end
local startDate = ngx.quote_sql_str(tostring(args["startDate"]));

--获得结束日期，再加一天
if args["endDate"] == nil or args["endDate"] == "" then
    ngx.say("{\"success\":false,\"info\":\"endDate参数错误！\"}");
    return;
end
local endDate = tostring(args["endDate"]);
--2015-08-12格式
local Y = string.sub(endDate, 1, 4);
local M = string.sub(endDate, 6, 7);
local D = string.sub(endDate, 9, 10);
 --把日期时间字符串转换成对应的日期时间
local dt1 = os.time{year=Y, month=M, day=D};
--根据时间单位和偏移量得到具体的偏移数据
local ofset = 60 * 60 * 24 * 1;
--指定的时间+时间偏移量，此时获得的是一个table值
local newTime = os.date("*t", dt1 + tonumber(ofset));
endDate = ngx.quote_sql_str(string.format('%d-%02d-%02d', newTime.year, newTime.month, newTime.day));

--3.连接数据库
local mysql = require "resty.mysql";
local db = mysql:new();
db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024*1024
}

local sql = "SELECT date(TIME) AS date ,COUNT(1) AS turnOut  FROM T_BAG_CQJSTW WHERE TEACHER_ID="..teacher_id.." AND STUDENT_ID = "..student_id.." AND TYPE_ID=1 AND TIME BETWEEN "..startDate.." AND "..endDate.." GROUP BY date(TIME)";
    
local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"更新数据出错！\"}");
    return;
end

local result = {};
result["success"] = true;
result["list"] = list;

--4.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 5.返回值
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);