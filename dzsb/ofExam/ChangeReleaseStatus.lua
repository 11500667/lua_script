#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#曹洪念 2015.9.9
#描述： 上传全部完毕后 更改base表中的release_status字段为1
#参数：资源id(resource_id)  
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

--2.获取参数
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = args["resource_id"]

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
		ngx.print("{\"success\":false,\"info\":\"数据库连接失败！\"}")
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 连接数据库失败!");
		return false;
	end
	
local responseObj = {};

--4.数据处理
-- 先查询 再更改
local sql = "SELECT resource_id_int from t_resource_base WHERE resource_id_int = "..resource_id;
local list, err, errno, sqlstate = db:query(sql);

if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询resource_id_int数据出错！\"}");
    return;
end

if (#list > 0) then

local sql2 = "UPDATE t_resource_base SET release_status = '1' WHERE resource_id_int ="..list[1]["resource_id_int"];
local list2, err, errno, sqlstate = db:query(sql2);

if not list2
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"更改release_status数据出错！\"}");
    return;
end

responseObj.success = true;
responseObj.info = "更改release_status成功";

else

responseObj.success = false;
responseObj.info = "资源不存在 更改release_status不成功";

end

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