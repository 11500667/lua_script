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
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误\"}")
    return
end

local person_id = args["person_id"]
local resource_id = args["resource_id"]

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

local sql = "SELECT t2.class_id,t2.class_name FROM t_resource_sendstudent AS t1 INNER JOIN t_base_class AS t2 on t1.class_id = t2.class_id WHERE t1.state_id = 4 and t1.resource_id = '"..resource_id.."' AND t1.sned_person = "..person_id.." GROUP BY t1.class_id";
local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local class_list = results;
local returnJson = {};
returnJson["success"] = true;
returnJson["list"] = class_list;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end