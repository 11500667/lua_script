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

ngx.log(ngx.ERR, "**********东师理想微课大赛*****获取大赛ID开始**********");

local querysql = "select id from t_rating_info where rating_type=4 and rating_status in (2,3,5,6) and b_use=1"
ngx.log(ngx.ERR,querysql)
local querysql_res = db:query(querysql)
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  return
end
local returnjson = {}
if querysql_res[1] == nil then
  returnjson["success"] = false
  returnjson["info"] = "未找到记录"
else
  local rating_id = querysql_res[1]["id"]
  returnjson["rating_id"] =rating_id
  returnjson["success"] = true
  returnjson["info"] = "查询成功"
end
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****获取大赛ID结束**********");
