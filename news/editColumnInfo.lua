--[[
#李政言 2015-2-9
#描述：编辑栏目(后台)
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

--column_name参数
if args["column_name"] == nil or args["column_name"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_name参数错误！\"}")
	return
end
local column_name = args["column_name"]


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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--修改栏目名称
local sql_update_column = "update t_news_column set column_name = '"..column_name.."' where column_id = "..column_id;

local results, err, errno, sqlstate = mysql_db:query(sql_update_column);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end
--修改ssdb中的值
--判断该栏目下是否有新闻
local sql_new_clumn = "SELECT  SQL_NO_CACHE id FROM t_news_info_sphinxse WHERE  QUERY='filter=column_id,"..column_id..";'";
local column_new = mysql_db:query(sql_new_clumn);
for i=1,#column_new do
    ssdb_db:multi_hset("news_info_"..column_new[i]["id"],"column_name",column_name);
end

ngx.say("{\"success\":\"true\",\"info\":\"修改栏目名称成功\"}");
-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)