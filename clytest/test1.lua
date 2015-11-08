#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#������ 2015-01-29
#������
]]
--1.��ȡ�����ķ���
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--2.��ȡ����id�����жϲ��������ȷ
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id��������\"}")
    return
end

local id = args["id"];
--��ȡ����student_name�����жϲ��������ȷ
if args["student_name"] == nil or args["student_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_name��������\"}")
    return
end

local student_name = args["student_name"];

--��ȡ����b_use�����жϲ��������ȷ
if args["b_use"] == nil or args["b_use"] == "" then
    ngx.say("{\"success\":false,\"info\":\"b_use��������\"}")
    return
end

local b_use = args["b_use"];
--��ȡ����bureau_id�����жϲ��������ȷ
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id��������\"}")
    return
end

local bureau_id = args["bureau_id"];
--��ȡ����class_id�����жϲ��������ȷ
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id��������\"}")
    return
end

local class_id = args["class_id"];
--��ȡ����check_massage�����жϲ��������ȷ
if args["check_massage"] == nil or args["check_massage"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_massage��������\"}")
    return
end

local check_massage = args["check_massage"];


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
--4.����redis������
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--5.����ssdb������
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--д�����ݿ�
local student_res = "INSERT INTO t_base_student(STUDENT_ID,STUDENT_NAME,B_USE,BUREAU_ID,CLASS_ID,CHECK_MASSAGE) VALUES ("..id..",'"..student_name.."',"..b_use..","..bureau_id..","..class_id..","..check_massage..");";
local students_res, err, errno, sqlstate = db:query(student_res);
if not students_res then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end






--6.��mysql���ӹ黹�����ӳ�
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end

-- 7.��redis���ӹ黹�����ӳ�
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>��Redis���ӹ黹���ӳس���");
end

--8.�Żص�SSDB���ӳ�
ssdb_db:set_keepalive(0,v_pool_size);
















