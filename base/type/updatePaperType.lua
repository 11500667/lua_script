#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-17
#描述：修改试卷类型
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
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end
local id  = tostring(args["id"]);

if args["type_name"] == nil or args["type_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_name参数错误！\"}")
    return
end
local type_name  = tostring(args["type_name"]);

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
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
 local paper_map={};
 paper_map.paper_app_type_name = type_name
  
local sql_submit = "SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse  WHERE query='filter=PAPER_APP_TYPE,"..id.."';";
local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"修改类型出错！\"}");
	 return
end

local sql_psper_submit = "SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse  WHERE query='filter=PAPER_APP_TYPE,"..id.."';";
local result_paper, err, errno, sqlstate = db:query(sql_psper_submit)
if not result_paper then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"修改类型出错！\"}");
	 return
end

for i=1,#result do
   --修改数据库的表
   local update_paper_info = "UPDATE t_sjk_paper_info SET PAPER_APP_TYPE_NAME  ='"..type_name.."' where id="..result[i]["id"];
   db:query(update_paper_info); 
   --修改缓存
   cache:hmset("paper_"..result[i]["id"],paper_map);
end

for i=1,#result_paper do
   --修改数据库的表
   local update_paper_info = "UPDATE t_sjk_paper_my_info SET PAPER_APP_TYPE_NAME  ='"..type_name.."' where id="..result_paper[i]["id"];
   db:query(update_paper_info); 
   --修改缓存
   cache:hmset("mypaper_"..result[i]["id"],paper_map);
end

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

ngx.say("{\"success\":true,\"info\":\"修改类型成功\"}")












