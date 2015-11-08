#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-04
#描述：获得教师可以参与的检查列表
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

--传参数
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id  = tostring(args["person_id"]);

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);


--传参数
if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);



--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--获得人员所在学校的id
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local school_id = cache:hget("person_"..person_id.."_"..identity_id,"xiao");
--拼接sql语句
local sql_check_list = "SELECT check_id,check_name,status_id FROM t_resource_check_info WHERE  status_id =1  AND school_id ="..school_id;

local result_check, err, errno, sqlstate = db:query(sql_check_list)
	if not result_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	

--根据int_id获得对应的infoid
local sql_info_id = "";

if type_id == "1" then
    sql_info_id = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=resource_id_int,"..obj_id_int..";filter=group_id,2;'";
end
local result_infoid, err, errno, sqlstate = db:query(sql_info_id)
	 if not result_infoid then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
	
local obj_info_id = result_infoid[1]["id"];


--拼接sql语句
local sql_check_list = "SELECT t2.check_id,t2.check_name,t2.status_id FROM t_resource_sendcheck AS t1 INNER JOIN t_resource_check_info AS t2 on t1.check_id = t2.check_id WHERE  t2.status_id  =1 and t1.obj_info_id ="..obj_info_id.." AND t1.type_id ="..type_id;

local result_check_xz, err, errno, sqlstate = db:query(sql_check_list)
	if not result_check_xz then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};
local check_list = {};
for i=1,#result_check do
   local tab={};
   tab.check_id = result_check[i]["check_id"];
   tab.check_name = result_check[i]["check_name"];
   tab.status_id = result_check[i]["status_id"];
   tab.is_checked = 0;
   for j=1,#result_check_xz do
       if result_check[i]["check_id"] == result_check_xz[j]["check_id"] then
	      tab.is_checked = 1;
	   end
   end
   
   check_list[i] = tab;
end
resultJson.success = true;
resultJson.list = check_list;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end
ngx.say(responseJson);
