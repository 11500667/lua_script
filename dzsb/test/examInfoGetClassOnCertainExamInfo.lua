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
--参数
local resource_id = args["resource_id"];
local person_id = args["person_id"];

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

local sql = "SELECT sjstate.CLASS_ID AS class_id,class.CLASS_NAME AS class_name,sjstate.is_exam AS tested FROM T_BAG_SJSTATE sjstate INNER JOIN T_BASE_CLASS class ON sjstate.CLASS_ID=class.CLASS_ID WHERE class.B_USE=1 AND sjstate.CLASS_ID IN (SELECT CLASS_ID FROM T_BASE_CLASS_SUBJECT classsubject WHERE TEACHER_ID = "..person_id..") AND sjstate.RESOURCE_ID='"..resource_id.."'";
local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local person_list = results;
local returnJson = {};
returnJson["success"] = true;
returnJson["list"] = person_list;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
