#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#������ 2014-01-24
#����������subject_id��ö�Ӧ�Ŀ�Ŀ���ƺ�ѧ������
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
--��ÿ�Ŀid
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id��������\"}")
    return
end
--local subject_id = args["subject_id"]
local subject_id = ngx.quote_sql_str(args["subject_id"])
--ngx.log(ngx.ERR,"======"..subject_id)

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

local  sel_scheme_name = "SELECT SCHEME_ID,SCHEME_NAME FROM t_resource_scheme WHERE  TYPE_ID =3 AND SUBJECT_ID =  "..subject_id;


-- 4.��ѯ�汾id�Ͱ汾����
local results, err, errno, sqlstate = db:query(sel_scheme_name);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end
local scheme_id = results[1]["SCHEME_ID"];
--����scheme_id��ö�Ӧ�Ľṹid
local sel_structure = "SELECT STRUCTURE_ID,STRUCTURE_NAME FROM t_resource_structure WHERE is_root = 1 AND SCHEME_ID_INT = "..scheme_id;

-- 4.����scheme_id��ö�Ӧ�Ľṹid
local results_structure, err, errno, sqlstate = db:query(sel_structure);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

local responseObj = {};
responseObj.success = true;
responseObj.scheme_id =  results[1]["SCHEME_ID"];
responseObj.structure_id =  results_structure[1]["STRUCTURE_ID"];
responseObj.structure_name =  results_structure[1]["STRUCTURE_NAME"];

-- 5.��table����ת����json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.���json����ҳ��
ngx.say(responseJson);

-- 7.��mysql���ӹ黹�����ӳ�
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end









