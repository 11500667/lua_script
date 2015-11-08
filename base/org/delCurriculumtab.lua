--[[
#��ѩ�� 2015-2-3
#������ɾ���γ̱�(��̨)
]]

ngx.header.content_type = "text/plain;charset=utf-8"
local cjson = require "cjson"

-- 1.��ȡ����
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--����mysql���ݿ�
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

local id = args["id"]

local del = mysql_db:query("delete from t_base_kechengbiao where id = "..id..";")

--��������
local currinfo = {}
if del == nil or del == "" then 
	currinfo.success = false
	currinfo.info = "ȡ������ʧ��"
	ngx.say(cjson.encode(currinfo))
else
	currinfo.success = true
	currinfo.info = "ȡ�����óɹ�"
end

-- ��mysql���ӹ黹�����ӳ�
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end