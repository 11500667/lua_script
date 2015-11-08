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

--title参数
if args["title"] == nil or args["title"] == "" then
	ngx.print("{\"success\":false,\"info\":\"title参数错误！\"}")
	return
end
local title = args["title"]

--content参数
if args["content"] == nil or args["content"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"content参数错误！\"}")
	return
end
local content = args["content"]

--column_id参数
if args["column_id"] == nil or args["column_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_id参数错误！\"}")
	return
end
local column_id = args["column_id"]

--images参数
if args["image"] == nil or args["image"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"image参数错误！\"}")
	return
end
local image = args["image"]

local cjson = require "cjson" 
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

local column_name = "无"
if column_id ~= "-1" then 
	local column_tab = mysql_db:query("select column_name from t_news_column where column_id = "..column_id..";")
	column_name = column_tab[1]["column_name"]
end

--更新数据库
mysql_db:query("update t_news_info set title = '"..title.."', update_ts = "..update_ts..",column_id="..column_id.." where id="..id.." and regist_id = "..regist_id..";")
--更新SSDB
local ssdb_info = {}
ssdb_info["title"] = title
ssdb_info["content"] = content
ssdb_info["update_ts"] = update_ts
ssdb_info["image"] = image
ssdb_info["column_id"] = column_id
ssdb_info["column_name"] = column_name
local ok,err = ssdb_db:multi_hset("news_info_"..id,ssdb_info)

mysql_db: set_keepalive(0, v_pool_size);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true}")

