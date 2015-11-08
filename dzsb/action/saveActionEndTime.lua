#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#������ 2014-02-02
#�������û���������ʱ���¼
]]
--1.��ò�������
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
--2.��ò�������
--�����ʾid
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id��������\"}")
    return
end
local id = tostring(args["id"]);

local create_time = ngx.localtime();
--3.�������ݿ�
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
local up_record = "UPDATE T_BAG_CQJSTW SET END_TIME='"..create_time.."' WHERE ID="..id;

-- 4.���û���Ϊ��¼������
local results, err, errno, sqlstate = db:query(up_record);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

-- 6.���json����ҳ��
ngx.say("{\"success\":true}")

-- 7.��mysql���ӹ黹�����ӳ�
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end









