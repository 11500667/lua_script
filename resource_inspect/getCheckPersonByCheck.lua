#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-13
#描述：获得检查人员列表
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
if args["check_id"] == nil or args["check_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_id参数错误！\"}")
    return
end
local check_id  = tostring(args["check_id"]);

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


--拼接sql语句
local sql_check_list = "SELECT identity_id,person_id,subject_id,subject_name,stage_id,stage_name FROM t_resource_check_person_subject WHERE check_id = "..check_id;

local result_check, err, errno, sqlstate = db:query(sql_check_list)
	if not result_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};
local check_list = {};
for i=1,#result_check do
   local tab={};
   tab.check_id = result_check[i]["person_id"];
   tab.subject_id = result_check[i]["subject_id"];
   tab.subject_name = result_check[i]["subject_name"];
   tab.stage_id = result_check[i]["stage_id"];
   tab.stage_name = result_check[i]["stage_name"];
   local person_name = cache:hget("person_"..result_check[i]["person_id"].."_"..result_check[i]["identity_id"],"person_name");
    tab.person_name = result_check[i]["person_name"];
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












