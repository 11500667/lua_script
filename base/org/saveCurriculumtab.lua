--[[
#梁雪峰 2015-2-3
#描述：课表设置(后台)
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

--获取参数
local class_id = args["class_id"]
local week = args["week"]
local kejie = args["kejie"]
local xq_id = args["xq_id"]
local subject_id = args["subject_id"]
local person_id = args["person_id"]

--插入数据库
local ins = mysql_db:query("INSERT INTO t_base_kechengbiao (class_id,week,kejie,xq_id,subject_id,person_id) value("..class_id..","..week..","..kejie..","..xq_id..","..subject_id..","..person_id..")")
local id = ins.insert_id

--返回数据
local currinfo = {}
if id = nil or id == "" then 
	currinfo.success = false
	currinfo.info = "课程设置失败"
	ngx.say(cjson.encode(currinfo))
else
	currinfo.success = true
	currinfo.info = "课程设置成功"
	currinfo.id = id
	ngx.say(cjson.encode(currinfo))
end

-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end