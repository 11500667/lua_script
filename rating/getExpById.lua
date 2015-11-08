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

--person_id
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]


local returnjson = {}
local querysql = "select id,stage_id,subject_id,status,login_id,login_pwd from t_rating_experts where rating_id='"..rating_id.."' and person_id='"..person_id.."'"
ngx.log(ngx.ERR,querysql)
local experts, err, errno, sqlstate = db:query(querysql)

if not experts then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
if experts[1] == nil   then
  ngx.say("{\"success\":false,\"info\":\"无此专家信息\"}")
  return
else
  local stage_id = experts[1]["stage_id"];
  local subject_id = experts[1]["subject_id"];
  if stage_id == ngx.null then
    ngx.say("{\"success\":false,\"info\":\"此专家未维护学段学科\"}")
    return
  else
    returnjson.stage_id = stage_id
    returnjson.subject_id = subject_id
	
	stage_info = db:query("SELECT stage_name FROM   t_dm_stage WHERE  STAGE_ID = "..stage_id.." ")
	returnjson.stage_name = stage_info[1]["stage_name"]

	subject_info = db:query("SELECT subject_name FROM   t_dm_subject WHERE  SUBJECT_ID = "..subject_id.." ")
	returnjson.subject_name = subject_info[1]["subject_name"]
	
	
  end


end
returnjson.id = experts[1]["id"];
returnjson.status = experts[1]["status"];
returnjson.login_id = experts[1]["login_id"];
returnjson.login_pwd = experts[1]["login_pwd"];

returnjson.success = true
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))






















































