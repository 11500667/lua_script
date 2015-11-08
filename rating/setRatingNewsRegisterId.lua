
ngx.header.content_type = "text/plain;charset=utf-8"
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

--person_id
if args["rating_type"] == nil or args["rating_type"] == "" then
  ngx.say("{\"success\":false,\"info\":\"rating_type参数错误！\"}")
  return
end
local rating_type = args["rating_type"]

if args["regist_id"] == nil or args["regist_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
  return
end
local regist_id = args["regist_id"]


local countsql = "select count(*) as count from t_rating_news where rating_type = "..rating_type.." "

local count_res, err, errno, sqlstate = db:query(countsql)
ngx.log(ngx.ERR,countsql)
if not count_res then
	ngx.log(ngx.ERR, "err: ".. err);
	return
end
local count1 = count_res[1]["count"]
local querysql=""
if tonumber(count1) == 0 then
	querysql = "insert into t_rating_news (rating_type,regist_id) values ("..rating_type..","..regist_id..") "
else
	querysql = "update t_rating_news set regist_id = "..regist_id.." where rating_type = "..rating_type..""
end

local res, err, errno, sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not res then
	ngx.log(ngx.ERR, "err: ".. err);
	return
end

local returnjson = {}
returnjson.success = true
returnjson.info = "修改成功"
	
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))



















