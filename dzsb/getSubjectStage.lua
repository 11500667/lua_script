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
--local subject_id = args["subject_id"]
local subject_id = ngx.quote_sql_str(args["subject_id"])
--ngx.log(ngx.ERR,"======"..subject_id)

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

local  sel_scheme_name = "SELECT SCHEME_ID,SCHEME_NAME FROM t_resource_scheme WHERE  TYPE_ID =3 AND SUBJECT_ID =  "..subject_id;


-- 4.查询版本id和版本名称
local results, err, errno, sqlstate = db:query(sel_scheme_name);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end
local scheme_id = results[1]["SCHEME_ID"];
--根据scheme_id获得对应的结构id
local sel_structure = "SELECT STRUCTURE_ID,STRUCTURE_NAME FROM t_resource_structure WHERE is_root = 1 AND SCHEME_ID_INT = "..scheme_id;

-- 4.根据scheme_id获得对应的结构id
local results_structure, err, errno, sqlstate = db:query(sel_structure);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
responseObj.success = true;
responseObj.scheme_id =  results[1]["SCHEME_ID"];
responseObj.structure_id =  results_structure[1]["STRUCTURE_ID"];
responseObj.structure_name =  results_structure[1]["STRUCTURE_NAME"];

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









