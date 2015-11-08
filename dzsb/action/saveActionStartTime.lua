#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-02-02
#描述：用户动作开始时间记录
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
--获得教师id
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
local teacher_id = tostring(args["teacher_id"]);
--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end
local student_id = tostring(args["student_id"]);
--获得行为类型id
if args["action_type"] == nil or args["action_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"action_type参数错误！\"}")
    return
end
local action_type = tostring(args["action_type"]);

local answer_type = -1;
if action_type == "5" then
    --获得答案类型id
   if args["answer_type"] == nil or args["answer_type"] == "" then
       ngx.say("{\"success\":false,\"info\":\"answer_type参数错误！\"}")
       return
    end
    answer_type = tostring(args["answer_type"]);
end
local create_time = ngx.localtime();
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

local  in_record = "INSERT INTO T_BAG_CQJSTW(STUDENT_ID,TIME,TYPE_ID,TEACHER_ID,ANSWER_TYPE,END_TIME) VALUE ("..student_id..",'"..create_time.."',"..action_type..","..teacher_id..","..answer_type..",-1)";

-- 4.将用户行为记录到表中
local results, err, errno, sqlstate = db:query(in_record);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

 local id = results.insert_id;
-- 6.输出json串到页面
ngx.say("{\"success\":true,\"id\":"..id.."}")


-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end









