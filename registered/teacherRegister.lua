ngx.log(ngx.ERR,"教师注册开始")

--获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
  args = ngx.req.get_uri_args();
else
  ngx.req.read_body();
  args = ngx.req.get_post_args();
end

local cjson = require "cjson"


--login_name登录户名
if args["login_name"] == nil or args["login_name"] == "" then
  ngx.print("{\"success\":false,\"info\":\"login_name参数错误！\"}")
  return
end
local login_name = args["login_name"]
--login_password登录密码
if args["login_password"] == nil or args["login_password"] == "" then
  ngx.print("{\"success\":false,\"info\":\"login_password参数错误！\"}")
  return
end
local login_password = ngx.md5(tostring(args["login_password"]))

--school_id--学校ID  departmen_id--部门ID  name--姓名  sex--性别  stage_id--学段  subject_id--学段  email--邮箱  tel--电话  login_name--登录户名  login_password--登录密码

local school_id = args["school_id"]
local departmen_id = args["departmen_id"]
local name = args["name"]
local sex = args["sex"]
local stage_id = args["stage_id"]
local subject_id = args["subject_id"]
local email = args["email"]
local tel = args["tel"]
local provinceId = ""
local cityId = ""
local districtId = ""
local orgId = ""

-- 获取数据库连接
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
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end


--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
  ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
  return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
  ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
  return
end

--school_id--学校ID  departmen_id--部门ID  name--姓名  sex--性别  stage_id--学段  subject_id--学段  email--邮箱  tel--电话  login_name--登录户名  login_password--登录密码

local res = db:query("select org_id,province_id,city_id,district_id From t_base_organization where BUREAU_ID = "..school_id..";")
local returnjson = {}
if res == nil then
  returnjson.success = false
  returnjson.info = "查询数据库失败"
  return
else
  orgId=res[1]["org_id"]
  provinceId=res[1]["province_id"]
  cityId=res[1]["city_id"]
  districtId=res[1]["district_id"]
end

local resstage, err, errno, sqlstate = db:query("select stage_name From t_dm_stage where STAGE_ID = "..stage_id..";")
ngx.log(ngx.ERR,"select stage_name From t_dm_stage where STAGE_ID = "..stage_id..";")
if not res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local ressubject, err, errno, sqlstate = db:query("select subject_name From t_dm_subject where SUBJECT_ID = "..subject_id..";")
ngx.log(ngx.ERR,"select subject_name From t_dm_subject where SUBJECT_ID = "..subject_id..";")
if not res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local stage_name = resstage[1]["stage_name"]
local subject_name = ressubject[1]["subject_name"]

local insstusql, err, errno, sqlstate = db:query("INSERT INTO t_base_person (STAGE_NAME,SUBJECT_NAME,SUBJECT_ID,PERSON_NAME,XB_NAME,TEL,EMAIL,ORG_ID,BUREAU_ID,DISTRICT_ID,CITY_ID,PROVINCE_ID,CREATE_TIME,B_USE,IDENTITY_ID,DISPLAY,STAGE_ID) VALUES ('"..stage_name.."','"..subject_name.."','"..subject_id.."','"..name.."','"..sex.."','"..tel.."','"..email.."','"..orgId.."','"..school_id.."','"..districtId.."','"..cityId.."','"..provinceId.."',now(),2,5,1,'"..stage_id.."');")
ngx.log(ngx.ERR,"INSERT INTO t_base_person (SUBJECT_ID,PERSON_NAME,XB_NAME,TEL,EMAIL,ORG_ID,BUREAU_ID,DISTRICT_ID,CITY_ID,PROVINCE_ID,CREATE_TIME,B_USE,IDENTITY_ID,DISPLAY,STAGE_ID) VALUES ('"..subject_id.."','"..name.."','"..sex.."','"..tel.."','"..email.."','"..orgId.."','"..school_id.."','"..districtId.."','"..cityId.."','"..provinceId.."',now(),2,5,1,'"..stage_id.."');")
if not insstusql then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local stuid=insstusql.insert_id

local inslogsql, err, errno, sqlstate = db:query("INSERT INTO t_sys_loginperson (PERSON_ID,PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,audit_status) VALUES ('"..stuid.."','"..name.."','"..login_name.."','"..login_password.."',5,1,2);")
ngx.log(ngx.ERR,"INSERT INTO t_sys_loginperson (PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,audit_status) VALUES ('"..name.."','"..login_name.."','"..login_password.."',5,1,2);")
if not inslogsql then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


ngx.log(ngx.ERR,"stuid:========================================="..stuid)
--存入缓存login_+name
local token = ngx.md5(tostring(stuid.."_5".."_dsideal4r5t6y7u"))

local setLoginResult = redis_db: hmset("login_" ..login_name, "person_id",stuid,"identity_id","5","person_name",name,"pwd",login_password,"b_use","1","token",token,"audit_status","2" )
--存入缓存person_人员ID_身份ID
local res1, err, errno, sqlstate = db:query("insert into t_base_chat(CHAT_TYPE) values (2);")
ngx.log(ngx.ERR,"insert into t_base_chat(CHAT_TYPE) values (2);")
if not res1 then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local chatid = res1.insert_id
local setPersonResult = redis_db: hmset("person_" ..stuid.."_5","sys_chatid",chatid,"person_name",name,"avatar_url","default_person.png","bm","10","sheng",provinceId,"shi",cityId,"qu",districtId,"xiao",school_id,"token",token )

--存入组缓存
local setPersonResult = redis_db: sadd("group_" ..stuid.."_5",1)
local setPersonResult = redis_db: sadd("group_" ..stuid.."_5",provinceId)
local setPersonResult = redis_db: sadd("group_" ..stuid.."_5",cityId)
local setPersonResult = redis_db: sadd("group_" ..stuid.."_5",districtId)
local setPersonResult = redis_db: sadd("group_" ..stuid.."_5",school_id)
local setPersonResult = redis_db: sadd("group_" ..stuid.."_5",orgId)


returnjson.success = true
returnjson.info = "教师注册成功"
cjson.encode_empty_table_as_object(false)


db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb_db:set_keepalive(0,v_pool_size)

ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))

























  