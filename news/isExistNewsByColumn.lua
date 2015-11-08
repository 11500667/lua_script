--[[
#李政言 2015-2-9
#描述：判断该栏目下是否存在新闻(后台)
]]
ngx.header.content_type = "text/plain;charset=utf-8"

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--获得栏目id
--column_id参数
if args["column_id"] == nil or args["column_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_id参数错误！\"}")
	return
end
local column_id = args["column_id"]

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

--判断该栏目下是否有新闻
local sql_new_clumn = "SELECT  SQL_NO_CACHE  id FROM t_news_info_sphinxse WHERE  QUERY='filter=column_id,"..column_id..";'";
local column_new = mysql_db:query(sql_new_clumn);

if #column_new >0 then
    ngx.say("{\"success\":false,\"info\":\"改栏目下存在新闻！\"}")
else
    ngx.say("{\"success\":true,\"info\":\"该栏目下不存在新闻！\"}") 
end

-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end