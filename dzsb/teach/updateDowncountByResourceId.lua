#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-23
#描述：每次传来一个resource_id，downcount增加1
]]

--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
 local myts = require "resty.TS";
 
 --获得参数resource_id，并且判断参数是否正确

if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = args["resource_id"];

--连接数据库
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

local downcount_res = "UPDATE t_bag_resource_info SET DOWN_COUNT=DOWN_COUNT+1 WHERE RESOURCE_ID='"..resource_id.."'";
local results, err, errno, sqlstate = db:query(downcount_res);
if not results then 
ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.print("{\"success\":\"false\",\"info\":\"数据更新出错！\"}");
    return
end

--将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.print("{\"success\":\"false\",\"info\":\"将Mysql数据库连接归还连接池出错！\"}");
end

ngx.say("{\"success\":true,\"info\":\"更改下载次数成功！\"}");









