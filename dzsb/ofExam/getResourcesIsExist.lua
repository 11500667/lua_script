#ngx.header.content_type = "text/plain;charset=utf-8"

--[[
#caohn 2015-08-12
#描述：获取将要上传的文件（课件/学案/电子书/测试）是否存在
#参数 资源id：resource_id 人员id：person_id
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

--2获取参数
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = ngx.quote_sql_str(tostring(args["resource_id"]));

--获得人员id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = ngx.quote_sql_str(tostring(args["person_id"]));

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
--1：同一人正在上传同一资源，0：此人没上传过这个资源，2：不同人上传同一资源
--查询是否是不同人上传同一资源
local sql = "SELECT COUNT(*) as count FROM t_resource_base WHERE RESOURCE_ID_INT ="..resource_id.."AND CREATE_PERSON !="..person_id.."and release_status in (1,3)"

local list, err, errno, sqlstate = db:query(sql);
if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

local result = {} 
result["success"] = true

if list[1]["count"] == "1"
then
   result["isExist"] = 2
else
	local sql2 = "SELECT COUNT(*) as count FROM t_resource_base WHERE RESOURCE_ID_INT ="..resource_id.."AND CREATE_PERSON ="..person_id.."and release_status in (1,3)"
	ngx.log(ngx.ERR,"###############sql:",sql2);
	local list2, err, errno, sqlstate = db:query(sql2);
	if not list2
	then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"list2查询数据出错！\"}");
    return;
	end

	result["isExist"] = list2[1]["count"]
	--如果是同一人上传同一资源  需要返回资源标题和更新标识
	
	--获取资源标题 在base表中
	if list2[1]["count"] == "1"
	then
	local  sql3 = "SELECT RESOURCE_TITLE as title FROM t_resource_base WHERE RESOURCE_ID_INT ="..resource_id.."AND CREATE_PERSON ="..person_id.."and release_status in (1,3)"
	
	ngx.log(ngx.ERR,"##################",sql3)
	local list3, err, errno, sqlstate = db:query(sql3);
	if not list3
	then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"list3查询数据出错！\"}");
    return;
	end;
	
	--获取更新标识 在teach_info表中
	local  sql4 = "SELECT updatelogo as update_logo FROM t_resource_teach_info WHERE RESOURCE_ID_INT ="..resource_id
	ngx.log(ngx.ERR,"############",sql4)
	
	local list4, err, errno, sqlstate = db:query(sql4);
	if not list4
	then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"list4查询数据出错！\"}");
    return;
	end 
	
	result["title"] = list3[1]["title"]
	result["update_logo"] = list4[1]["update_logo"]
	end
	
end

--5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--6.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJson = cjson.encode(result);

-- 7.输出json串到页面
ngx.say(resultJson);
