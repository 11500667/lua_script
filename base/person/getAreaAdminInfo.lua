#lzy 2015-3-15 ��ɽ��ƽͳһ�˺ŵ�¼
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--���жϲ����Ƿ���ȷ
if tostring(args["person_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id��������\"}")    
    return
end

--��ȡ��Աid
local person_id = tostring(args["person_id"])

local returnJson = {};
--����redis������
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


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


--����SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--�ж���Ա�Ƿ��ܹ���¼��̨

local ssdb_value = ssdb_db:exists("school_admin_person_"..person_id);

if ssdb_value[1] == "1" then
-- ������Աid��ѯ��Ӧ����id
local old_qu_id = cache:hget("person_"..person_id.."_5","qu");
-- ��ѯ������Ա����Աid
local  sel_new_person_id = "SELECT PERSON_ID FROM t_base_person WHERE bureau_id ="..old_qu_id.." and identity_id = 10";

local results, err, errno, sqlstate = db:query(sel_new_person_id);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

local new_person_id  = results[1]["PERSON_ID"];

-- ���������Ա�ĵ�¼��

local login_name_sql =  "SELECT login_name FROM t_sys_loginperson WHERE person_id = "..new_person_id.." and identity_id = 10";

local results_login_name, err, errno, sqlstate = db:query(login_name_sql);
if not results_login_name then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

local login_name = results_login_name[1]["login_name"];


-- ��װ��̨��¼����Ա��Ϣ
local admin_info,err = cache:hmget("login_"..login_name,"person_id","person_name","identity_id","token")
  if not admin_info then
     ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
     return
end

--��ù���Ա��ʡ����

local org_info,err = cache:hmget("person_"..admin_info[1].."_10","shi","qu","xiao","sheng");
  if not org_info then
     ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
     return
end
local role_str = "";
local role_info = cache:lrange("role_"..admin_info[1].."_10",0,-1)
    if #role_info ~= 0 then
	for j=1,#role_info,1 do
		   role_str = role_str..role_info[j]..",";
    end
end
returnJson["background_bureau_id"] = org_info[3];
returnJson["background_city_id"] = org_info[1];
returnJson["background_district_id"] = org_info[2];
returnJson["background_identity_id"] = admin_info[3];
returnJson["background_person_id"] = admin_info[1];
returnJson["background_person_name"] = admin_info[2];
returnJson["background_role_id"] = role_str;
returnJson["background_token"] = admin_info[4];
returnJson["background_user"] = login_name;
returnJson["background_province_id"] = org_info[4];
end
returnJson["success"] = true;
returnJson["is_admin"] =ssdb_value[1];	





local cjson = require "cjson";
--cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

-- 7.��mysql���ӹ黹�����ӳ�
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end

--�Żص�SSDB���ӳ�
ssdb_db:set_keepalive(0,v_pool_size);

--redis�Ż����ӳ�
cache:set_keepalive(0,v_pool_size)


	
