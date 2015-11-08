--[[
#梁雪峰 2015-2-3
#描述：删除新闻栏目(后台)
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
local cjson = require "cjson"
--获取参数
local regist_person = tostring(ngx.var.cookie_background_person_id)
local regist_id = args["regist_id"] 
local column_id = args["column_id"]
local info = {}
local res = mysql_db:query("select count(*) from t_news_regist where regist_id = "..regist_id.." and regist_person = "..regist_person..";")
ngx.log(ngx.ERR,"------------------------------>>>>>","select count(*) from t_news_regist where regist_id = "..regist_id.." and regist_person = "..regist_person..";")
if res[1]["count(*)"] == "0" or res == nil then 
	info.success = false
	info.info = "您无权限对该栏目进行修改"
	ngx.say(cjson.encode(info))
else
	local upd1 = mysql_db:query("update t_news_column SET b_delete = 1 where regist_id = "..regist_id.." and column_id = "..column_id..";")
	info.success = true
	info.info = "删除完成"
	ngx.say(cjson.encode(info))
end

-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end