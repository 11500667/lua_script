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

--scheme_id
if args["scheme_id"] == nil or args["scheme_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
  return
end
local scheme_id = args["scheme_id"]


local querysql = "select structure_id,structure_name from t_resource_structure where SCHEME_ID_INT='"..scheme_id.."' and (level=2 or level=1) and is_delete=0"
local ex, err, errno, sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not ex then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local returnjson = {}
returnjson.success = true
local personArray = {}
for i=1,#ex do
local tab = {}
tab.structure_id=ex[i]["structure_id"];
tab.structure_name=ex[i]["structure_name"];
table.insert(personArray, tab);
end
returnjson.list = personArray


cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))





