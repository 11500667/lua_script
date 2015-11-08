#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-17
#描述：获取当前学期时间
 涉及到的表：t_base_term
]]

--1.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
    ngx.log(ngx.ERR, err);
    return;
end

db:set_timeout(1000); -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024
}

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
    return;
end

--SFDQXQ代表是否当前学期，0：不是，1：是
local sql = "SELECT XN,XQ,KSRQ,JSRQ FROM t_base_term WHERE SFDQXQ=1";
local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

--学年
local XN = tonumber(list[1]["XN"]);
--学期，1：上学期，2：下学期
local XQ = tonumber(list[1]["XQ"]);
--开始时间
local KSRQ = tostring(list[1]["KSRQ"]);
--结束时间
local JSRQ = tostring(list[1]["JSRQ"]);

local result = {};
result["success"] = true;
result["start_term"] = XN.."-"..KSRQ;

if XQ == 1 then
	--上学期结束时间学年+1
	result["end_term"] = (XN + 1).."-"..JSRQ;
else
	--下学期结束时间
	result["end_term"] = XN.."-"..JSRQ;
end

-- 2.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 3.返回值
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);