#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
  ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
  return
end

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

if not ok then
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--t_rating_register表字段
--大赛id
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--作品名称WORKS_NAME
if args["works_name"] == nil or args["works_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"works_name参数错误！\"}")
    return
end
local works_name = args["works_name"]

--作品内容WORKS_CONTENT
if args["works_content"] == nil or args["works_content"] == "" then
    ngx.say("{\"success\":false,\"info\":\"works_content参数错误！\"}")
    return
end
local works_content = args["works_content"]

--作品版本WORKS_VERSION
local works_version = ""
if args["works_version"] == nil or args["works_version"] == "" then
	works_version = ""
else
	works_version = args["works_version"]
end

--指导教师名称INSTRUCTOR_NAME
local instructor_name = ""
if args["instructor_name"] == nil or args["instructor_name"] == "" then
    instructor_name = ""
else
	instructor_name = args["instructor_name"]
end

--指导教师性别INSTRUCTOR_SEX
local instructor_sex = ""
if args["instructor_sex"] == nil or args["instructor_sex"] == "" then
	instructor_sex = ""
else
	instructor_sex = args["instructor_sex"]
end

--指导教师民族INSTRUCTOR_NATION
local instructor_nation = ""
if args["instructor_nation"] == nil or args["instructor_nation"] == "" then
    instructor_nation = ""
else
	instructor_nation = args["instructor_nation"]
end

--指导教师电子邮箱INSTRUCTOR_EMAIL
local instructor_email = ""
if args["instructor_email"] == nil or args["instructor_email"] == "" then
	instructor_email = ""
else
	instructor_email = args["instructor_email"]
end

--指导教师单位INSTRUCTOR_COMPANY
local instructor_company = ""
if args["instructor_company"] == nil or args["instructor_company"] == "" then
    instructor_company = ""
else
	instructor_company = args["instructor_company"]
end

--指导教师电话INSTRUCTOR_TEL
local instructor_tel = ""
if args["instructor_tel"] == nil or args["instructor_tel"] == "" then
	instructor_tel = ""
else
	instructor_tel = args["instructor_tel"]
end

--person表字段
--民族NATION
if args["nation"] == nil or args["nation"] == "" then
    ngx.say("{\"success\":false,\"info\":\"nation参数错误！\"}")
    return
end
local nation = args["nation"]

--年龄AGE
if args["age"] == nil or args["age"] == "" then
    ngx.say("{\"success\":false,\"info\":\"age参数错误！\"}")
    return
end
local age = args["age"]

--身份证号IDENTITY_NUM
if args["indentity_num"] == nil or args["indentity_num"] == "" then
    ngx.say("{\"success\":false,\"info\":\"inentity_num参数错误！\"}")
    return
end
local indentity_num = args["indentity_num"]

--固定电话FIX_TEL
local fix_tel = ""
if args["fix_tel"] == nil or args["fix_tel"] == "" then
    fix_tel = ""
else
	fix_tel = args["fix_tel"]
end

--通信地址MALADDR
local maladdr = ""
if args["maladdr"] == nil or args["maladdr"] == "" then
	maladdr = ""
else
	maladdr = args["maladdr"]
end

--邮政编码POSCODE
local poscode = ""
if args["poscode"] == nil or args["poscode"] == "" then
	poscode = ""
else
	poscode = args["poscode"]
end

--移动电话tel
local tel = ""
if args["tel"] == nil or args["tel"] == "" then
	tel = ""
else
	tel = args["tel"]
end

--电子邮箱email
local email = ""
if args["email"] == nil or args["email"] == "" then
	email = ""
else
	email = args["email"]
end

--文件
local file_id = ""
if args["file_id"] == nil or args["file_id"] == "" then
	file_id = ""
else
	file_id = args["file_id"]
end

  local person_id = tostring(ngx.var.cookie_person_id)
  local qu_id = redis_db:hget("person_"..person_id.."_5","qu")
  local shi_id = redis_db:hget("person_"..person_id.."_5","shi")
  local sheng_id=redis_db:hget("person_"..person_id.."_5","sheng")
  local xiao_id=redis_db:hget("person_"..person_id.."_5","xiao")
  --人员ID
local countsql = "select count(*) as count from t_rating_register where rating_id='"..rating_id.."' and person_id='"..person_id.."';"
local count, err, errno, sqlstate = db:query(countsql)  
ngx.log(ngx.ERR,countsql)
if not count then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local count1 = count[1]["count"]
local sql =""
ngx.log(ngx.ERR, "=============================="..count1);
if tonumber(count1) == 0 then 
	sql = "INSERT INTO t_rating_register (PROVINCE_ID,CITY_ID,DISTRICT_ID,SCHOOL_ID,PERSON_ID,RATING_ID,WORKS_NAME,WORKS_CONTENT,WORKS_VERSION,INSTRUCTOR_NAME,INSTRUCTOR_SEX,INSTRUCTOR_NATION,INSTRUCTOR_EMAIL,INSTRUCTOR_COMPANY,INSTRUCTOR_TEL,file_id) VALUES ('"..sheng_id.."','"..shi_id.."','"..qu_id.."','"..xiao_id.."','"..person_id.."','"..rating_id.."','"..works_name.."','"..works_content.."','"..works_version.."','"..instructor_name.."','"..instructor_sex.."','"..instructor_nation.."','"..instructor_email.."','"..instructor_company.."','"..instructor_tel.."','"..file_id.."');"
else
	sql = "update t_rating_register set WORKS_NAME='"..works_name.."' , WORKS_CONTENT='"..works_content.."' , WORKS_VERSION='"..works_version.."' , INSTRUCTOR_NAME='"..instructor_name.."' , INSTRUCTOR_SEX='"..instructor_sex.."' , INSTRUCTOR_NATION='"..instructor_nation.."' , INSTRUCTOR_EMAIL='"..instructor_email.."' , INSTRUCTOR_COMPANY='"..instructor_company.."' , INSTRUCTOR_TEL='"..instructor_tel.."' , file_id='"..file_id.."' where rating_id='"..rating_id.."' and person_id='"..person_id.."'; "
end  
  
  

--插入报名表
local insstusql, err, errno, sqlstate = db:query(sql)
ngx.log(ngx.ERR,sql)
if not insstusql then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
--NATION,AGE,IDENTITY_NUM,FIX_TEL,MALADDR,POSCODE
--插入人员表

local insper="UPDATE t_base_person SET tel='"..tel.."',email='"..email.."', NATION='"..nation.."',AGE='"..age.."',IDENTITY_NUM='"..indentity_num.."',FIX_TEL='"..fix_tel.."',MALADDR='"..maladdr.."',POSCODE='"..poscode.."' where person_id='"..person_id.."'; "
local insperson, err, errno, sqlstate = db:query(insper)
ngx.log(ngx.ERR,insper)
if not insperson then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
--返回值
local returnjson = {}
returnjson.success = true

db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))


