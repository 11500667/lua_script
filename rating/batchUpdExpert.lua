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

--学段id
if args["stage_id"] == nil or args["stage_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
  return
end
local stage_id = args["stage_id"]

--学科id
if args["subject_id"] == nil or args["subject_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
  return
end
local subject_id = args["subject_id"]

--专家id
if args["exp_id"] == nil or args["exp_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"exp_id参数错误！\"}")
  return
end
local exp_id = args["exp_id"]

local updsql = "update t_rating_experts set stage_id='"..stage_id.."',subject_id='"..subject_id.."' where rating_id='"..rating_id.."' and id='"..exp_id.."'"
local ex, err, errno, sqlstate = db:query(updsql)
ngx.log(ngx.ERR,updsql)
if not ex then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


local returnjson = {}
returnjson.success = true
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))








