ngx.log(ngx.ERR,"学生注册开始")

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

local school_id = args["school_id"]
local class_id = args["class_id"]
local name = args["name"]
local sex = args["sex"]
local email = args["email"]
local tel = args["tel"]
local provinceId = ""
local cityId = ""
local districtId = ""
local orgId = ""

ngx.log(ngx.ERR,args["tel"])

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



local insstusql, err, errno, sqlstate = db:query("INSERT INTO t_base_student (B_USE,BUREAU_ID,CLASS_ID,STUDENT_NAME,XB_NAME,EMAIL,STU_TEL,CREATE_TIME) VALUES (2,'"..school_id.."','"..class_id.."','"..name.."','"..sex.."','"..email.."','"..tel.."',now());")
ngx.log(ngx.ERR,"INSERT INTO t_base_student (B_USE,BUREAU_ID,CLASS_ID,STUDENT_NAME,XB_NAME,EMAIL,STU_TEL,CREATE_TIME) VALUES (2,'"..school_id.."','"..class_id.."','"..name.."','"..sex.."','"..email.."','"..tel.."',now());")
if not insstusql then
  ngx.say("{\"success\":false,\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local stuid=insstusql.insert_id

local inslogsql, err, errno, sqlstate = db:query("INSERT INTO t_sys_loginperson (PERSON_ID,PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,audit_status) VALUES ('"..stuid.."','"..name.."','"..login_name.."','"..login_password.."',6,1,2);")
ngx.log(ngx.ERR,"INSERT INTO t_sys_loginperson (PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,audit_status) VALUES ('"..name.."','"..login_name.."','"..login_password.."',6,1,2);")
if not inslogsql then
  ngx.say("{\"success\":false,\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


--存入缓存login_+name

local token = ngx.md5(tostring(stuid.."_6".."_dsideal4r5t6y7u"))

local setLoginResult = redis_db: hmset("login_" ..login_name, "person_id",stuid,"identity_id","6","person_name",name,"pwd",login_password,"b_use","1","token",token,"audit_status","2" )


--存入缓存person_人员ID_身份ID
local res1, err, errno, sqlstate = db:query("insert into t_base_chat(CHAT_TYPE) values (2);")
ngx.log(ngx.ERR,"insert into t_base_chat(CHAT_TYPE) values (2);")
if not res1 then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local chatid = res1.insert_id
local setPersonResult = redis_db: hmset("person_" ..stuid.."_6","sys_chatid",chatid,"person_name",name,"avatar_url","default_person.png","bm","10","sheng",provinceId,"shi",cityId,"qu",districtId,"xiao",school_id,"token",token )


local returnjson = {}
returnjson.success = true

db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb_db:set_keepalive(0,v_pool_size)

ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))




  