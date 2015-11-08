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

--区id
if args["district_id"] == nil or args["district_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"district_id参数错误！\"}")
  return
end
local district_id = args["district_id"]

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end


local schoolIdQuery = "SELECT org_id,org_name FROM t_base_organization WHERE ORG_TYPE = 2 and B_USE = 1 and district_id ="..district_id.." "
local schoolCount, err, errno, sqlstate = db:query(schoolIdQuery)
ngx.log(ngx.ERR,schoolIdQuery)
if not schoolCount then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end



local array = {}
for i=1,#schoolCount do
  local ssdb_info = {};
  local schoolId = schoolCount[i]["org_id"];
  ssdb_info["schoolId"] = schoolId
  ssdb_info["schoolName"] = schoolCount[i]["org_name"];
  local sqlDis = "select count(*) as count,count(distinct person_id) as person_count from t_rating_resource where person_id  in (select person_id from  t_base_person where BUREAU_ID='"..schoolId.."') and rating_id='"..rating_id.."'"..w_type
  local countDis, err, errno, sqlstate = db:query(sqlDis)
  ngx.log(ngx.ERR,sqlDis)
  if not countDis then
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
  ssdb_info["count"] = countDis[1]["count"];
  ssdb_info["person_count"] = countDis[1]["person_count"];
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
