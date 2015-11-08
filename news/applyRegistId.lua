--[[
#梁雪峰 2015-2-3
#描述：新闻鉴权接口(后台)
]]

ngx.header.content_type = "text/plain;charset=utf-8"

--get args
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end
if not args then 
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--[[
local person_id = args["person_id"]
local identity_id = args["identity_id"]
if not person_id or string.len(person_id) == 0 or
	not identity_id or string.len(identity_id) == 0 then
	ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end
]]
local identity_id = tostring(ngx.var.cookie_background_identity_id)
local person_id = tostring(ngx.var.cookie_background_person_id)
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
local auinfo = {}
--local person_id = tostring(ngx.var.cookie_background_person_id)
--local identity_id = tostring(ngx.var.cookie_background_identity_id)
local create_time = os.date("%c")
--if tonumber(identity_id) ~= 1 and tonumber(identity_id) ~= 3 and tonumber(identity_id) ~= 4 and tonumber(identity_id) ~= 8 and tonumber(identity_id) ~= 9 and tonumber(identity_id) ~= 10  then 
--	auinfo.success = false
--	auinfo.info = "您不是管理员，无法注册"
--	ngx.say(cjson.encode(auinfo)) 
--	return
--end

local ins,err = mysql_db:query("insert into t_news_regist (regist_person,regist_time) values("..person_id..",now())")

--local regist_id = ins.insert_id
--local res = mysql_db:query("select count(*) from t_news_regist where regist_id = "..regist_id..";")

if not ins then 
	auinfo.success = false 
	auinfo.regist_id = "鉴权失败"
	ngx.say(cjson.encode(auinfo))
else
	local regist_id = ins.insert_id
	auinfo.success = true
	auinfo.regist_id = regist_id
	ngx.say(cjson.encode(auinfo))
end

-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
