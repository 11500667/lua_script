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


--WKDS_ID_INT
if args["wkds_id_int"] == nil or args["wkds_id_int"] == "" then
  ngx.say("{\"success\":false,\"info\":\"wkds_id_int参数错误！\"}")
  return
end
local wkds_id_int = args["wkds_id_int"]


--person_id
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]

--new_time
if args["new_time"] == nil or args["new_time"] == "" then
  ngx.say("{\"success\":false,\"info\":\"new_time参数错误！\"}")
  return
end
local new_time = args["new_time"]

local querysql = "update t_his_wk set  new_time="..new_time.."  where wkds_id_int = "..wkds_id_int.." and person_id="..person_id..";"
local update_now, err, errno, sqlstate = db:query(querysql)

local returnjson = {}
returnjson.success = true
cjson.encode_empty_table_as_object(false)
returnjson.success = true
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

















