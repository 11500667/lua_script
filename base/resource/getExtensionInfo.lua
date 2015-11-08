#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-06
#描述：获得所有可以上传的扩展名
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
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
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
local extensioninfo = "";
if type_id == "1" then
		local sel_extension = "SELECT extension_name FROM t_resource_extension WHERE extension_name != 'other'";
		local result_res, err, errno, sqlstate = db:query(sel_extension)
			if not result_res then
			 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"查询失败！\"}")
			 return
			end
		for i=1,#result_res do
		  extensioninfo = extensioninfo..","..result_res[i]["extension_name"]
		end
		extensioninfo = string.sub(extensioninfo,2,#extensioninfo)
elseif type_id == "2" then
		extensioninfo = "avi,mp4,wmv,flv";	
end

local cjson = require "cjson";
local resultJson={};
resultJson.success = true;
resultJson.extension = extensioninfo;
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);
