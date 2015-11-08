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

local sql = "SELECT SUBJECT_NAME,POINTNAME,WEEKDAY FROM t_base_kechengbiao WHERE CLASS_ID = "..class_id.." AND XQ_ID = "..xq_id;

local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local course_list = results;

local resinfo_json = {}
for i=1,6 do
	local res_json = {}
	res_json["weekday"] = i
	local num = 0;
	local course_json = {};
	for j=1,#course_list do
	    local tab = {};
		local weekday = course_list[j]["WEEKDAY"];
		 if weekday == i then
			num = num + 1;
			tab["courseName"] = course_list[j]["SUBJECT_NAME"];
			tab["pointName"] = course_list[j]["POINTNAME"];
			course_json[num] = tab;
		 end
	end
	res_json["course"] = course_json;
	resinfo_json[i] = res_json
end

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resinfo_json);

ngx.say(responseJson);

ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
