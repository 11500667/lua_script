#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-28
#描述：通过人员和角色获得产品
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
if args["role_ids"] == nil or args["role_ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"role_ids参数错误！\"}")
    return
end
local role_ids = tostring(args["role_ids"]);


local sel_sql = "SELECT DISTINCT t2.product_id,t2.product_name,t1.role_id FROM t_person_role_product as t1 INNER JOIN t_pro_product AS t2 ON t1.product_id = t2.PRODUCT_ID WHERE person_id = "..person_id.." AND identity_id ="..identity_id.." AND role_id IN ("..role_ids..")";

res, err, errno, sqlstate = db:query(sel_sql)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 ngx.say("操作失败")
    return
end

local cjson = require "cjson";
local result = {};
result.success = true;
result.list = res;
local responseJson = cjson.encode(result);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end 
ngx.print(responseJson);