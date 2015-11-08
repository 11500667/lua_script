local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--regist_id参数
if args["regist_id"] == nil or args["regist_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
	return
end
local regist_id = args["regist_id"]

--column_name参数
if args["column_name"] == nil or args["column_name"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_name参数错误！\"}")
	return
end
local column_name = args["column_name"]

local regist_person = tostring(ngx.var.cookie_background_person_id)

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

mysql_db:query("INSERT INTO t_news_column (column_name,create_person,create_time,regist_id,parent_id,b_delete) VALUES ('"..column_name.."',"..regist_person..",'"..ngx.localtime().."',"..regist_id..",-1,0)")

-- 将mysql连接归还到连接池
mysql_db: set_keepalive(0, v_pool_size);

ngx.print("{\"success\":true}")

