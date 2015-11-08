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

if args["shi_id"] == nil or args["shi_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"shi_id参数错误！\"}")
  return
end
local shi_id = args["shi_id"]

local disCount = "SELECT id,districtname FROM t_gov_district where cityid = "..shi_id..";"
local disC, err, errno, sqlstate = db:query(disCount)
ngx.log(ngx.ERR,disCount)
if not disC then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


local array = {}
for i=1,#disC do
  local ssdb_info = {};
  local districtId = disC[i]["id"];
  ssdb_info["district_id"] = districtId
  ssdb_info["district_name"] = disC[i]["districtname"]
  local sqlDis = "select count(*) as count from t_rating_register where rating_id='"..rating_id.."' and district_id='"..districtId.."';"
  local countDis, err, errno, sqlstate = db:query(sqlDis)
  ngx.log(ngx.ERR,sqlDis)
  if not countDis then
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
  ssdb_info["count"] = countDis[1]["count"];
  table.insert(array, ssdb_info);
end
local returnjson = {}
returnjson.success = true
returnjson.list = array
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))
















