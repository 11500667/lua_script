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

--id参数
if args["id"] == nil or args["id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"id参数错误！\"}")
	return
end
local id = args["id"]


local TS = require "resty.TS"

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

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

--生成一个update_ts
local update_ts = TS.getTs()

--删除操作
mysql_db:query("update t_news_info set b_delete = 1,update_ts="..update_ts.." where id = "..id.." and regist_id="..regist_id..";")

local sdb = ssdb_db:multi_hset("news_info_"..id,"b_delete","1","update_ts",update_ts)

mysql_db: set_keepalive(0, v_pool_size);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true}")