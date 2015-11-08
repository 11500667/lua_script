local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误\"}")
    return
end

if args["xq_id"] == nil or args["xq_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"xq_id参数错误\"}")
    return
end

local class_id = args["class_id"]
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

local sql = "SELECT subject_name,pointname,weekday FROM t_base_kechengbiao WHERE CLASS_ID = "..class_id.." AND XQ_ID = "..xq_id;

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
