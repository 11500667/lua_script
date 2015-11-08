#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-12
#描述：标记试卷状态
 参数：class_id：班级id     resource_id：试卷id    state:状态
 涉及到的表：t_bag_sjstate
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
--获得班级id
if args["class_id"] == nil or args["class_id"] == ""
then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误！\"}");
    return;
end
local class_id = tonumber(args["class_id"]);

--获得试卷id
if args["resource_id"] == nil or args["resource_id"] == ""
then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}");
    return;
end
local resource_id = ngx.quote_sql_str(tostring(args["resource_id"]));

--获得班级id
if args["state"] == nil or args["state"] == ""
then
    ngx.say("{\"success\":false,\"info\":\"state参数错误！\"}");
    return;
end
local state = tonumber(args["state"]);

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
local sql = "";
if state == 1 then
    --当前时间，即为当前考试时间，做记录
    local dt = ngx.quote_sql_str(tostring(ngx.localtime()));
    sql = "UPDATE t_bag_sjstate SET is_exam="..state..",exam_time="..dt.." WHERE class_id="..class_id.." AND resource_id="..resource_id..";";
else
    sql = "UPDATE t_bag_sjstate SET is_exam="..state.." WHERE class_id="..class_id.." AND resource_id="..resource_id..";";
end

local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"更新数据出错！\"}");
    return;
end

local result = {};
result["success"] = true;

-- 5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
ngx.say(tostring(cjson.encode(result)));