--[[
#梁雪峰 2014-12-23
#描述：获取编辑新闻详情(后台)
]]

ngx.header.content_type = "text/plain;charset=utf-8"
local cjson = require "cjson"

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

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

--得到前台参数
local person_id = tostring(ngx.var.cookie_background_person_id)
local id = args["id"]

--编辑新闻属性
local news_info = {}

--判断该新闻是否为删除状态。
local search_news_info = mysql_db:query("select b_delete from t_news_info where id = "..id.." and  person_id = "..person_id..";")

if search_news_info[1]["b_delete"] == "1" then
	news_info.success = false
	news_info.info = "该新闻已被删除,无法编辑"
end

--获取编辑新闻属性
local sdb = ssdb_db:multi_hget("news_"..id,"title","content","image","news_abstract")

if sdb == nil then 
	news_info.success = false
	news_info.info = "获取编辑新闻信息失败"
	ngx.say(cjson.encode(news_info))
else
	news_info.success = true
	news_info.news_id = id
	news_info.title = sdb[2]
	news_info.content = sdb[4]
	news_info.image = cjson.decode(sdb[6])
	news_info.news_abstract = sdb[8]
	ngx.say(cjson.encode(news_info))
end

-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
