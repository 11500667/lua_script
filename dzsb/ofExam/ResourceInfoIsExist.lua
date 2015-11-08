#ngx.header.content_type = "text/plain;charset=utf-8"

--[[
#曹洪念 2015-08-12
#描述：判断服务器上文件是否存在（用于二次验证资源是否存在，解决显示和下载中间的时间段文件被删除的问题）
#参数 资源id resource_id
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
		ngx.print("{\"success\":false,\"info\":\"连接数据库失败！\"}")
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 连接数据库失败!");
		return false;
	end

--4.数据查询
--查询该资源在服务器上是否存在
local sql = "SELECT COUNT(*) as count FROM t_resource_base WHERE RESOURCE_ID_INT = "..resource_id.." and release_status in (1,3)"
local list, err, errno, sqlstate = db:query(sql);
if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

local result = {} 
result["success"] = true

if list[1]["count"] > "0"
then
	result["isExist"] = true  
	local sql2 = "SELECT updatelogo as update_logo FROM t_resource_teach_info WHERE RESOURCE_ID_INT = "..resource_id;
	local updatelogo, err, errno, sqlstate = db:query(sql2);
	
	if not updatelogo
	then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"updatelogo查询数据出错！\"}");
    return;
	end
	
	result["update_logo"] = updatelogo[1]["update_logo"]
else
	result["isExist"] = false
end

-- 5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 6.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJson = cjson.encode(result);

-- 7.输出json串到页面
ngx.say(resultJson);