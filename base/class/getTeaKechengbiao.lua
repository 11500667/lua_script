local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误\"}")
    return
end

if args["xq_id"] == nil or args["xq_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"xq_id参数错误\"}")
    return
end

local person_id = args["person_id"]
local xq_id = args["xq_id"]
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

local sql = "SELECT t3.class_name,t1.weekday,t1.pointname,t1.subject_name FROM t_base_kechengbiao as t1 INNER JOIN t_base_class_subject AS t2 on t1.class_id=t2.class_id  and t1.xq_id = t2.xq_id and t1.subject_id = t2.subject_id INNER JOIN t_base_class AS t3 on t1.class_id = t3.class_id WHERE teacher_id = "..person_id.." AND t1.XQ_ID = "..xq_id;

local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":false,\"info\":\"查询数据出错！\"}");
    return
end

local course_list = results;

local returnJson = {};
returnJson["weekday_count"] = 6;
returnJson["point_count"] = 8;
returnJson["success"] = true;
returnJson["list"] = course_list;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
