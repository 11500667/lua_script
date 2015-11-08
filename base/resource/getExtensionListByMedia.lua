#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-06
#描述：根据扩展名获得对应的媒体类型
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
local resultJson={};
local jsonStr = {};
--local filter_str = "";
if type_id == "1" then
	local sel_extension = "SELECT ID,MEDIA_TYPE FROM t_resource_mediatype";
	local result_res, err, errno, sqlstate = db:query(sel_extension)
		if not result_res then
				 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				  ngx.say("{\"success\":false,\"info\":\"查询失败！\"}")
				 return
		end

local sql_extension = "SELECT extension_name FROM t_resource_extension WHERE extension_name != 'other' and mediatype_id =";
	for i=1,#result_res do
		local extension_str  = "";
		local tab1 = {};
		tab1.disc = result_res[i]["MEDIA_TYPE"].."文件";
		
		local result_extension = db:query(sql_extension..result_res[i]["ID"]);
		
		for j=1,#result_extension do
			extension_str = extension_str..","..result_extension[j]["extension_name"];
		end
        if #extension_str>1 then
		     extension_str = string.sub(extension_str,2,#extension_str)
		end
		tab1.content = extension_str;
		table.insert(resultJson,tab1);
	end

elseif type_id == "2" then
   local tab1 = {};
   tab1.disc = "视频文件";
   tab1.content = "avi,mp4,wmv,flv";
   table.insert(resultJson,tab1)
end

local cjson = require "cjson";


jsonStr.success = true;
jsonStr.list = resultJson;
local responseJson = cjson.encode(jsonStr);
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);
