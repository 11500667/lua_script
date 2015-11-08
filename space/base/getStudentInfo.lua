#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#������ 2014-12-30
#����������ѧ��id��ö�Ӧ��ѧ������,id�ԡ������ָ�
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

--2.��ò���
--���ѧ��id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id��������\"}")
    return
end
local student_id = args["student_id"]

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


local sel_student= "SELECT student_id,student_name FROM t_base_student WHERE class_id = (SELECT class_id from t_base_student WHERE student_id = "..student_id..") AND B_USE = 1";
-- local sel_student = "SELECT student_id,student_name,login_name FROM t_base_student AS T1 INNER JOIN t_sys_loginperson AS T2 ON T1.STUDENT_ID = T2.PERSON_ID WHERE T1.class_id = (SELECT T1.class_id from t_base_student AS T1 WHERE T1.student_id = "..ngx.quote_sql_str(student_id)..") AND T2.IDENTITY_ID = 6";
local results, err, errno, sqlstate = db:query(sel_student);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

--���ÿռ�ӿ�ȡ������Ϣ
local personIds = {}
for i=1,#results do
    table.insert(personIds, results[i].student_id)
end
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfo("6", unpack(personIds))
for i=1,#results do
    for _, v in ipairs(rt) do
        if tostring(results[i].student_id) == tostring(v.personId) then
            results[i].avatar_fileid = v and v.avatar_fileid or ""
            --teacherlist[i].description = v and v.person_description or ""
            break
        end
    end
end

--��ѯ��ע���
local attentionService = require "space.attention.service.AttentionService"
local param = {}
param.personid = student_id
param.identityid = "6"
param.page_size = 100000
param.page_num = 1
--ngx.log(ngx.ERR,cjson.encode(param))
local at = attentionService.queryAttention(param)
for i=1,#results do
    results[i].attention = 0
    for _, v in ipairs(at) do
        if tostring(results[i].student_id) == tostring(v.personId) then
            results[i].attention = 1
            break
        end
    end
end

local responseObj = {};
local recordsPerson = {};

for i=1, #results do
	local temp_personId= results[i]["student_id"];
	local temp_personName = results[i]["student_name"];
	--local temp_loginname =  results[i]["login_name"];
    local temp_avatar_fileid = results[i]["avatar_fileid"];
    local temp_attention = results[i]["attention"];

	local record = {};
	record.id = temp_personId;
	record.name = temp_personName;
	record.userPhoto = "0";	
    record.avatar_fileid = temp_avatar_fileid;
    record.attention = temp_attention;
	--record.loginname = temp_loginname;
	table.insert(recordsPerson, record);
end

responseObj.success = true;
responseObj.studentlist = recordsPerson;

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









