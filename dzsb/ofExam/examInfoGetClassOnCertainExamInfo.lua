#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-11
#描述：获取班级关于某次考试的列表
 参数：teacher_id：老师的ID resource_id：试卷大id
 返回值：class_id、class_name、tested
 涉及到的表：
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
local teacher_id = tonumber(args["teacher_id"]);

--获得试卷resource_id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}");
    return;
end
local resource_id = ngx.quote_sql_str(tostring(args["resource_id"]));

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
    max_packet_size = 1024 * 1024
}

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
    return;
end

--4.查询数据
local sql = "SELECT class_id FROM t_base_class_subject WHERE teacher_id="..teacher_id.." GROUP BY class_id;";
local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询class_id数据出错！\"}");
    return;
end
local class_ids = "";
for i=1, #list do
	class_ids = class_ids..ngx.quote_sql_str(tostring(list[i]["class_id"]))..",";
end
if class_ids ~= "" then
	class_ids = string.sub(class_ids, 0, #class_ids - 1);
end

sql = "SELECT sjstate.class_id AS class_id,class.class_name AS class_name,sjstate.is_exam AS tested FROM t_bag_sjstate sjstate INNER JOIN t_base_class class ON sjstate.class_id=class.class_id WHERE class.b_use=1 AND sjstate.class_id IN ("..class_ids..") AND sjstate.resource_id="..resource_id..";";
    
list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询考试列表出错！\"}");
    return;
end

--5.返回数据
local result = {};
result["success"] = true;
result["list"] = list;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);

--6.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end