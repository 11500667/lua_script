#ngx.header.content_type = "text/plain;charset=utf-8"

--[[
#曹洪念 2015-08-12
#描述：学生获取未下载试卷的信息
#参数：学生id 试卷id
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

--2.获取参数
--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end
local student_id = args["student_id"]

--获得试卷大id
if args["tea_stid"] == nil or args["tea_stid"] == "" then
    ngx.say("{\"success\":false,\"info\":\"tea_stid参数错误！\"}")
    return
end
local tea_stid = args["tea_stid"]

--3.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
	if not db then 
		ngx.log(ngx.ERR, err);
		return;
	end

db:set_timeout(1000); -- 1 sec

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
  
--4.数据处理 
local sql = "SELECT t1.id,t1.state_id,t2.is_exam,t2.state_id AS is_open,t3.resource_title,t3.resource_size,t4.person_name as create_person, t3.create_time as create_time ,t3.file_id,t3.update_logo,t3.subject_id FROM t_resource_sendstudent t1 INNER JOIN t_bag_sjstate t2 ON t1.resource_id = t2.resource_id AND t1.class_id = t2.class_id INNER JOIN t_resource_base t3 ON t1.resource_id = t3.resource_id_int INNER JOIN t_base_person t4 ON t4.PERSON_ID = t3.create_person WHERE t1.resource_id = '" ..tea_stid .. "' AND t1.student_id = '"..student_id.."'"

ngx.log(ngx.ERR,"##################"..sql)
 
local list, err, errno, sqlstate = db:query(sql);
if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

local result = {} 
result["success"] = true
result["list"] = list

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