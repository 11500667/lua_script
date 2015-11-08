#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
--[[
--������login_name
if args["login_name"]==nil or args["login_name"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"��������\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> ����login_name����Ϊ�գ�");
    return
end
local login_name = tostring(args["login_name"]);
ngx.log(ngx.ERR,"login_name"..login_name)
--]]
--������person_id
if args["person_id"]==nil or args["person_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"��������\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> ����person_id����Ϊ�գ�");
    return
end
local person_id = tostring(args["person_id"]);

--������identity_id
if args["identity_id"]==nil or args["identity_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"��������\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> ����identity_id����Ϊ�գ�");
    return
end
local identity_id = tostring(args["identity_id"]);


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

--[[
local logininfo = cache:hmget("login_"..login_name,"person_id","identity_id","person_name");
 if tostring(logininfo[1]) == "userdata: NULL" then
      ngx.say("{\"success\":\"false\",\"info\":\"11�����ڴ��û�\"}")
    return
 end
--ngx.say("{\"success\":\"true\",\"person_id\":\""..logininfo[1].."\",\"identity_id\":\""..logininfo[2].."\",\"person_name\":\""..logininfo[3].."\"}")
--]]
local personinfo = cache:hmget("person_"..person_id.."_"..identity_id,"sheng","shi","xiao","person_name");
local responseObj = {};
responseObj.success = true;
responseObj.person_name = personinfo[4];
responseObj.identity_id = identity_id;

--local person_id = logininfo[1];
--ngx.log(ngx.ERR,"person_"..person_id.."_"..logininfo[2]);


local sheng_id = personinfo[1];

local shi_id = personinfo[2];

if identity_id == "6" then
     local org_id = personinfo[3];
	 --ngx.log(ngx.ERR,"--------------"..org_id.."-------------")
	 local sel_studentinfo = "SELECT t2.province_id as province_id,t1.class_id,ifnull(t1.email,'') as email,t2.org_name,t2.city_id as city_id FROM t_base_student AS t1 INNER JOIN  t_base_organization AS t2 ON t1.bureau_id = t2.org_id WHERE t2.org_id = "..org_id;
   
		   local results_studentinfo , err, errno, sqlstate = db:query(sel_studentinfo);
	 	if not results_studentinfo then
         ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	     ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
        return
     end
     --���ݰ༶id��ð༶����
	 local sel_class = "SELECT class_name from t_base_class where class_id =" ..results_studentinfo[1]["class_id"];

	   local results_class , err, errno, sqlstate = db:query(sel_class);
	 	if not results_class then
         ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	     ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
        return
     end
	 
	responseObj.email = results_studentinfo[1]["email"];
	responseObj.school = results_studentinfo[1]["org_name"];
	responseObj.class_name = results_class[1]["class_name"];
	sheng_id = results_studentinfo[1]["province_id"];
	shi_id = results_studentinfo[1]["city_id"];
	responseObj.person_photo= "0";
	 
else 
    

--���ѧУ����

local sel_xiao = "SELECT org_name FROM t_base_organization WHERE org_id = "..personinfo[3];

local results_xiao, err, errno, sqlstate = db:query(sel_xiao);
if not results_xiao then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

local school = results_xiao[1]["org_name"];

responseObj.school= school;

--���������Ϣ

local sel_email = "SELECT ifnull(email,'') as  email,avatar_url FROM t_base_person WHERE person_id = "..ngx.quote_sql_str(person_id).." and identity_id = "..ngx.quote_sql_str(identity_id);

local results_email, err, errno, sqlstate = db:query(sel_email);
if not results_email then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

local email = results_email[1]["email"];

responseObj.email= email;
responseObj.person_photo= results_email[1]["avatar_url"];

end


--���ʡ����
local sel_sheng = "SELECT PROVINCENAME from t_gov_province WHERE ID ="..sheng_id;

local results_sheng, err, errno, sqlstate = db:query(sel_sheng);
if not results_sheng then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end


--���������
local sel_shi = "SELECT cityname FROM t_gov_city WHERE ID ="..shi_id;

local results_shi, err, errno, sqlstate = db:query(sel_shi);
if not results_shi then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"��ѯ���ݳ���\"}");
    return
end

local sheng_name = results_sheng[1]["PROVINCENAME"];
local shi_name = results_shi[1]["cityname"];
responseObj.area= sheng_name..shi_name;
responseObj.qq="";

-- ��table����ת����json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);


-- ���json����ҳ��
ngx.say(responseJson);


-- ��redis���ӹ黹�����ӳ�
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>��Redis���ӹ黹���ӳس���");
end


