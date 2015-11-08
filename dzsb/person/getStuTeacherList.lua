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

local class_id = args["class_id"]

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

local sql = "SELECT t3.subject_name,t2.person_name,IFNULL(t2.tel,'--') AS tel FROM t_base_class_subject t1 INNER JOIN t_base_person t2 ON t1.TEACHER_ID = t2.PERSON_ID INNER JOIN t_dm_subject t3 ON t1.SUBJECT_ID = t3.SUBJECT_ID WHERE CLASS_ID = "..class_id.." AND XQ_ID = (SELECT XQ_ID FROM t_base_term WHERE sfdqxq=1)";
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