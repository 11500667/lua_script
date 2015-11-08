#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-12-30
#描述：根据学生id获得对应的学生姓名,id以“，”分隔
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
--获得学生id
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end
local id = args["id"]
--local id = ngx.quote_sql_str(args["id"])

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
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end

local  sel_student_name = "SELECT STUDENT_ID,STUDENT_NAME,t1.CLASS_ID AS CLASS_ID,t2.CLASS_NAME AS CLASS_NAME FROM t_base_student AS t1 INNER JOIN t_base_class AS t2 ON t1.CLASS_ID = t2.CLASS_ID  WHERE t1.STUDENT_ID in ("..id..")";

-- 4.查询学生对应的名称记录
local results, err, errno, sqlstate = db:query(sel_student_name);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
local recordsStudent = {};

for i=1, #results do
	local temp_studentId= results[i]["STUDENT_ID"];
	local temp_studentName = results[i]["STUDENT_NAME"];
	local temp_classID = results[i]["CLASS_ID"];
	local temp_className = results[i]["CLASS_NAME"];

	local record = {};
	record.studentID = temp_studentId;
	record.studentName = temp_studentName;
	record.classID = temp_classID;
	record.className = temp_className;
	
	table.insert(recordsStudent, record);
end

responseObj.success = true;
responseObj.list = recordsStudent;

-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.输出json串到页面
ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end









