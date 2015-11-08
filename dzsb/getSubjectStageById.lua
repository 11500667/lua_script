#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-01-24
#描述：根据subject_id获得对应的科目名称和学段名称
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
--获得科目id
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = ngx.quote_sql_str(args["subject_id"])

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

--根据根据subject_id获得对应的科目名称和学段名称
local sel_subject = "SELECT subject_id,subject_name,t1.stage_id as stage_id,stage_name FROM t_dm_subject AS t1,t_dm_stage AS t2 WHERE t1.stage_id = t2.stage_id and t1.subject_id ="..subject_id;

-- 4.根据根据subject_id获得对应的科目名称和学段名称
local results, err, errno, sqlstate = db:query(sel_subject);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
responseObj.success = true;
responseObj.subject_id =  results[1]["subject_id"];
responseObj.subject_name =  results[1]["subject_name"];
responseObj.stage_id =  results[1]["stage_id"];
responseObj.stage_name =  results[1]["stage_name"];

-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.输出json串到页面
ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end









