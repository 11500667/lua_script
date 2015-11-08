#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-27
#描述：通过角色的code码获得对应的产品
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

--传参数
if args["role_code"] == nil or args["role_code"] == "" then
    ngx.say("{\"success\":false,\"info\":\"role_code参数错误！\"}")
    return
end
local role_code  = tostring(args["role_code"]);

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

if args["role_id"] == nil or args["role_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"role_id参数错误！\"}")
    return
end
local role_id  = tostring(args["role_id"]);

local platform_id;
local system_id;

if role_code == "product_zy" then
	platform_id = 1;
	system_id = 1;
elseif role_code == "prodtct_office" then
    platform_id = 3;
	system_id = 1;
elseif role_code == "product_teach" then
	platform_id = 2;
	system_id = 1;
elseif role_code == "product_st" then
	platform_id = 1;
	system_id = 2;
elseif role_code == "product_sj" then
	platform_id = 1;
	system_id = 3;
end
local sel_pro = "SELECT product_id,product_name FROM t_pro_product WHERE PLATFORM_ID = "..platform_id.." AND SYSTEM_ID ="..system_id;
local pro_list = db:query(sel_pro);

local sel_check_pro ="SELECT DISTINCT t2.product_id,t2.product_name,t1.role_id FROM t_person_role_product as t1 INNER JOIN t_pro_product AS t2 ON t1.product_id = t2.PRODUCT_ID WHERE person_id = "..person_id.." AND identity_id ="..identity_id.." AND role_id ="..role_id;

--获得已经分配的产品
local check_pro_list = db:query(sel_check_pro);
local result = {};
for i=1,#pro_list do
   local tab = {};
   tab.product_id = pro_list[i]["product_id"];
   tab.product_name = pro_list[i]["product_name"];
   tab.ischecked = 0;
   for j=1,#check_pro_list do
	 if pro_list[i]["product_id"] == check_pro_list[j]["product_id"] then
	    tab.ischecked = 1;
     end  
   end
   result[i] = tab;  
end

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJson = {};
resultJson.success = true;
resultJson.list = result;
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end 
ngx.print(responseJson);