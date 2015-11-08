#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-21
#描述：根据学生id查询出STUDENT_ID,STUDENT_NAME,CLASS_ID
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--参数STUDENT_ID
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end
--往数据库中插入SQL语句时候用
local student_id = ngx.quote_sql_str(args["student_id"])

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

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
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end


local student_res = "SELECT STUDENT_ID,STUDENT_NAME,CLASS_ID FROM t_base_student WHERE STUDENT_ID ="..student_id;
local results, err, errno, sqlstate = db:query(student_res);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local student_info = results

local result = {};
result.success = true;
result.list = student_info;
--将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local data = cjson.encode(result);

ngx.say(data);




















