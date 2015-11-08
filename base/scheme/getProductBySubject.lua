#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-23
#描述：通过学段id获得对应的产品
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
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["scheme_id"] == nil or args["scheme_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end
local scheme_id  = tostring(args["scheme_id"]);

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

local sel_pro = "SELECT product_id,product_name FROM t_pro_product WHERE SUBJECT_ID = "..subject_id.." AND PLATFORM_ID = 1";
local sel_pro_check = "SELECT t1.b_use,t2.product_id,product_name FROM t_resource_product_scheme AS t1 INNER JOIN t_pro_product AS t2 ON t1.product_id = t2.product_id WHERE t1.b_use=1 and t1.scheme_id ="..scheme_id.." AND t2.SUBJECT_ID="..subject_id.." AND t2.PLATFORM_ID = 1";

local result_pro, err, errno, sqlstate = db:query(sel_pro)
	if not result_pro then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  ngx.say("{\"success\":false,\"info\":\"查询产品失败1！\"}")
	 return
    end
	
local result_pro_check, err, errno, sqlstate = db:query(sel_pro_check)
	if not result_pro_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  ngx.say("{\"success\":false,\"info\":\"查询产品失败2！\"}")
	 return
    end
local resultJson = {};	
local list = {};
for i=1,#result_pro do
     local tab = {};
	 tab.product_id = result_pro[i]["product_id"];
	 tab.product_name = result_pro[i]["product_name"];
	 tab.checked = 0;
    for j=1,#result_pro_check do
	  if result_pro[i]["product_id"] == result_pro_check[j]["product_id"] then  
	  tab.checked =1
	  end
	end
list[i] =tab; 
end
resultJson.list = list;
resultJson.success = true;
-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);
