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

--4.����redis������
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end



--local sel_teacher= "SELECT T1.TEACHER_ID AS TEACHER_ID FROM t_base_class_subject AS T1 INNER JOIN t_base_student AS T2 ON T1.CLASS_ID = T2.CLASS_ID WHERE T2.STUDENT_ID = "..student_id;
local sel_teacher= "SELECT cs.teacher_id AS TEACHER_ID FROM t_base_term bt,t_base_class_subject cs,t_base_student bs WHERE bt.xq_id = cs.xq_id AND cs.class_id = bs.class_id AND bt.sfdqxq = 1 AND cs.b_use = 1 AND bs.student_id ="..student_id;
-- local sel_teacher="SELECT T1.TEACHER_ID AS TEACHER_ID,T3.LOGIN_NAME AS LOGIN_NAME FROM t_base_class_subject AS T1 INNER JOIN t_base_student AS T2 INNER JOIN t_sys_loginperson AS T3 ON T1.CLASS_ID = T2.CLASS_ID AND T1.TEACHER_ID = T3.PERSON_ID WHERE T3.IDENTITY_ID = 5 AND T2.STUDENT_ID ="..ngx.quote_sql_str(student_id);
local results, err, errno, sqlstate = db:query(sel_teacher);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

--���ÿռ�ӿ�ȡ������Ϣ
local personIds = {}
for i=1,#results do
    table.insert(personIds, results[i].TEACHER_ID)
end
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfo("5", unpack(personIds))
for i=1,#results do
    for _, v in ipairs(rt) do
        if tostring(results[i].TEACHER_ID) == tostring(v.personId) then
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
        if tostring(results[i].TEACHER_ID) == tostring(v.personId) then
            results[i].attention = 1
            break
        end
    end
end

local responseObj = {};
local recordsPerson = {};

for i=1, #results do
	local temp_personId= results[i]["TEACHER_ID"];
    local temp_avatar_fileid = results[i]["avatar_fileid"];
	--���ݽ�ʦid��ö�Ӧ�Ľ�ʦ����
	local temp_personinfo =  cache:hmget("person_"..temp_personId.."_5","person_name","avatar_url");
    local temp_attention = results[i]["attention"];
   -- local temp_loginname = results[i]["LOGIN_NAME"];
	local record = {};
	record.id = temp_personId;
	record.name = temp_personinfo[1];
	record.userPhoto = temp_personinfo[2];
	--record.logiNname = temp_loginname;
    record.avatar_fileid = temp_avatar_fileid;
    record.attention = temp_attention;
	
	table.insert(recordsPerson, record);
end

responseObj.success = true;
responseObj.teacherlist = recordsPerson;

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

-- ��redis���ӹ黹�����ӳ�
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>��Redis���ӹ黹���ӳس���");
end










