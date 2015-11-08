#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-27
#描述：设置人员，角色，产品的关系
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
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id  = tostring(args["person_id"]);

--传参数
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);

--传参数
if args["role_id"] == nil or args["role_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"role_id参数错误！\"}")
    return
end
local role_id = tostring(args["role_id"]);


if args["del_productids"] == nil  then
    ngx.say("{\"success\":false,\"info\":\"del_productids参数错误！\"}")
    return
end
local del_productids  = tostring(args["del_productids"]);

if args["add_productids"] == nil  then
    ngx.say("{\"success\":false,\"info\":\"add_productids参数错误！\"}")
    return
end
local add_productids  = tostring(args["add_productids"]);

local sql_del="";
if #del_productids >0 then
	local del_productids_tab = Split(del_productids,",");
	for i=1,#del_productids_tab do
		local str= "DELETE FROM t_person_role_product where person_id = "..person_id.." and role_id = "..role_id.." and product_id = "..del_productids_tab[i]..";";
		sql_del = sql_del..str;
	end
end
local sql_add="";
if #add_productids >0 then
     sql_add = "insert into t_person_role_product(person_id,identity_id,role_id,product_id) values";
	local add_productids_tab = Split(add_productids,",");
	for i=1,#add_productids_tab do
		local str= "("..person_id..","..identity_id..","..role_id..","..add_productids_tab[i].."),"
		sql_add = sql_add..str;
	end
	
end

if #sql_add> 0 then

	sql_add = string.sub(sql_add,0,#sql_add-1)
	sql_add = sql_add..";";
end

-- 事务提交
local sql_submit="start transaction;"..sql_del..sql_add.."commit;" ;
ngx.log(ngx.ERR,"====================="..sql_submit);

res, err, errno, sqlstate = db:query(sql_submit)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 ngx.say("操作失败")
    return
end

local cjson = require "cjson";
local result = {};
result.success = true;
local responseJson = cjson.encode(result);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end 
ngx.print(responseJson);