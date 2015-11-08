#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-01-20
#描述：
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
--获得idS
if args["ids"] == nil or args["ids"] == "" then   
    ngx.say("{\"success\":false,\"info\":\"ids参数错误！\"}")
    return
end
local ids = args["ids"]
local id_list = Split(ids,",");
local id = "";
for i=1, #id_list do
--ids= ngx.quote_sql_str(ids);
     id = ngx.quote_sql_str(id_list[i])..","..id;
end
id = string.sub(id,0,#id-1)




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

local  sel_person_name = "SELECT PERSON_ID,PERSON_NAME FROM t_base_person WHERE PERSON_ID IN ("..id..")";

-- 4.查询学生对应的名称记录
local results, err, errno, sqlstate = db:query(sel_person_name);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
local recordsPerson = {};

for i=1, #results do
	local temp_personId= results[i]["PERSON_ID"];
	local temp_personName = results[i]["PERSON_NAME"];

	local record = {};
	record.personID = temp_personId;
	record.personName = temp_personName;
	
	table.insert(recordsPerson, record);
end

responseObj.success = true;
responseObj.list = recordsPerson;

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









