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


--大赛id
if args["rating_id"] == nil or args["rating_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
  return
end
local rating_id = args["rating_id"]

local person_id
if args["person_id"] == nil or args["person_id"] == "" then
  person_id = tostring(ngx.var.cookie_person_id)
else
  person_id = args["person_id"]
end

local countsql = "select count(*) as count from t_rating_register where rating_id='"..rating_id.."' and person_id='"..person_id.."';"
local count, err, errno, sqlstate = db:query(countsql)
if not count then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local count1 = count[1]["count"]


local sqlRating = "select works_name,works_content,works_version,instructor_name,instructor_sex,instructor_nation,instructor_email,instructor_company,instructor_tel,file_id from t_rating_register where rating_id='"..rating_id.."' and person_id='"..person_id.."';"
local ratingQuery, err, errno, sqlstate = db:query(sqlRating)
ngx.log(ngx.ERR,sqlRating)
if not ratingQuery then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local sqlPerson = "select nation,age,identity_num from t_dswk_login where person_id='"..person_id.."';"
local personQuery, err, errno, sqlstate = db:query(sqlPerson)
ngx.log(ngx.ERR,sqlPerson)
if not personQuery then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local returnjson = {}
returnjson.success = true
ngx.log(ngx.ERR,"=========================="..count1)
if tonumber(count1) == 0 then
  returnjson.works_name = ""
  returnjson.works_content = ""
  returnjson.works_version = ""
  returnjson.instructor_name = ""
  returnjson.instructor_sex = ""
  returnjson.instructor_nation = ""
  returnjson.instructor_email = ""
  returnjson.instructor_company = ""
  returnjson.instructor_tel = ""
  returnjson.nation = ""
  returnjson.age = ""
  returnjson.identity_num = ""
  returnjson.fix_tel = ""
  returnjson.maladdr = ""
  returnjson.poscode = ""
  returnjson.file_id = ""
else

  returnjson.works_name = ratingQuery[1]["works_name"]
  returnjson.works_content = ratingQuery[1]["works_content"]
  returnjson.works_version = ratingQuery[1]["works_version"]
  returnjson.instructor_name = ratingQuery[1]["instructor_name"]
  returnjson.instructor_sex = ratingQuery[1]["instructor_sex"]
  returnjson.instructor_nation = ratingQuery[1]["instructor_nation"]
  returnjson.instructor_email = ratingQuery[1]["instructor_email"]
  returnjson.instructor_company = ratingQuery[1]["instructor_company"]
  returnjson.instructor_tel = ratingQuery[1]["instructor_tel"]
  if personQuery[1] == nil then
  else
	returnjson.nation = personQuery[1]["nation"]
	returnjson.age = personQuery[1]["age"]
	returnjson.identity_num = personQuery[1]["identity_num"]
	returnjson.fix_tel = personQuery[1]["fix_tel"]
	returnjson.maladdr = personQuery[1]["maladdr"]
	returnjson.poscode = personQuery[1]["poscode"]
  end
  

  returnjson.file_id = ratingQuery[1]["file_id"]
end


db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))


