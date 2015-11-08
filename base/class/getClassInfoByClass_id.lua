#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-21
#描述：根据班级id查询出class_id,class_name,entrance_year,stage_id,bureau_id
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--1.参数CLASS_ID
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误！\"}")
    return
end
local class_id = ngx.quote_sql_str(args["class_id"])

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);


--2.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
    ngx.log(ngx.ERR, err);
    return;
end

  db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end


local class_res = "SELECT CLASS_ID,CLASS_NAME,ENTRANCE_YEAR,STAGE_ID,BUREAU_ID FROM t_base_class WHERE CLASS_ID ="..class_id;
--查询班级对应的名称记录
local results, err, errno, sqlstate = db:query(class_res);
if not results then 
   ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end
local class_info = results

local result = {};
result.success = "true";
result.list = class_info;
-- 3.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(cjson.encode(result));

