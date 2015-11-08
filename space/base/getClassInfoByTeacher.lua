#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-12-30
#描述：根据学生id获得对应的学生姓名,id以“，”分隔
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

--2.获得参数
--获得人员id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

local subject_id = args["subject_id"]

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


local responseObj = {};
local recordsClass = {};


local sel_class = "SELECT t1.class_id as class_id,class_name,t2.subject_id as subject_id FROM t_base_class AS t1 INNER JOIN t_base_class_subject AS t2 on t1.class_id = t2.class_id INNER JOIN t_base_term t3 on t3.XQ_ID = t2.XQ_ID and t3.SFDQXQ=1 WHERE teacher_id = "..ngx.quote_sql_str(person_id);


if subject_id ~= nil then
    sel_class = sel_class.." and subject_id = "..subject_id;
end

ngx.log(ngx.ERR,"sel_class->"..sel_class)
local results_class, err, errno, sqlstate = db:query(sel_class);
if not results_class then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

for i=1, #results_class do
    local temp_personId= results_class[i]["class_id"];
    local temp_personName = results_class[i]["class_name"];
    local temp_subject = results_class[i]["subject_id"];

    local record = {};
    record.id = temp_personId;
    record.name = temp_personName;
    record.subject_id = temp_subject;
    table.insert(recordsClass, record);
end

responseObj.classlist = recordsClass;
responseObj.success = true;

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









