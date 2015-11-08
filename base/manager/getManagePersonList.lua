#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-15
#描述：获得区县管理员列表
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
if args["unit_id"] == nil or args["unit_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"unit_id参数错误！\"}")
    return
end
local unit_id  = tostring(args["unit_id"]);

if args["unit_type"] == nil or args["unit_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"unit_type参数错误！\"}")
    return
end
local unit_type  = tostring(args["unit_type"]);


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

local sql_submit = "SELECT unit_name,create_time,person_id,identity_id FROM t_base_maneger WHERE b_use = 1 and unit_type = "..unit_type.." and unit_id = "..unit_id;

local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"设置区县管理员！\"}");
	 return
end
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local person_list={};
local resultJson = {};

for i=1,#result do
    local tab={};
	tab["unit_name"] = result[i]["unit_name"];
	tab["create_time"] = result[i]["create_time"];
	tab["person_id"] = result[i]["person_id"];
	tab["identity_id"] = result[i]["identity_id"];
	--从redis中获得人员名称
	local person_name = cache:hget("person_"..result[i]["person_id"].."_5","person_name");
    tab.person_name = person_name;
    person_list[i] = tab
	
end
resultJson.success = true;
resultJson.person_list = person_list;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);












