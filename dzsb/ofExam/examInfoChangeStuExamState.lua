#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-11
#描述：修改学生试卷的状态 
 参数：resource_ids：(小ID)试题的id的组合json字符串 state_id:状态的id
 涉及到的表：t_resource_sendstudent
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

--2.获得参数方法
--获得状态id
if args["state_id"] == nil or args["state_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"state_id参数错误！\"}");
    return;
end
local state_id = tonumber(args["state_id"]);

--获取试卷的id数组
if args["resource_ids"] == nil or args["resource_ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_ids参数错误！\"}");
    return;
end
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resource_ids = cjson.decode(args["resource_ids"]);
local resource_ids_list = resource_ids.list;
if resource_ids_list == nil then
    ngx.say("{\"success\":false,\"info\":\"resource_ids参数list格式错误！\"}");
    return;
end
local res_str = "";
for i=1, #resource_ids_list do
	if resource_ids_list[i]["id"] == nil or resource_ids_list[i]["id"] == "" then
		ngx.say("{\"success\":false,\"info\":\"resource_ids参数list的id格式错误！\"}");
		return;
	end
	res_str = res_str..ngx.quote_sql_str(tostring(resource_ids_list[i]["id"]))..",";
end
if res_str ~= "" then
	res_str = string.sub(res_str,0,#res_str-1);
end

--3.连接数据库
local mysql = require "resty.mysql";
local db = mysql:new();
db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024*1024
}

local sql = "UPDATE t_resource_sendstudent SET state_id="..state_id.." WHERE id IN ("..res_str..");";
    
local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"更新数据出错！\"}");
    return;
end

local result = {};
result["success"] = true;

--4.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 5.返回值
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);