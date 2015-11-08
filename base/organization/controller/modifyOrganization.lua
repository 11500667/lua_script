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

--orgId
local orgIdStr = ""
local org_id = ""
if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return
else
  org_id = args["org_id"]
  orgIdStr = "and ORG_ID="..org_id
end

if args["org_name"] == nil or args["org_name"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_name参数错误！\"}")
  return
end
local orgName = args["org_name"]

local sort_id=0;
if args["sort_id"] == nil or args["sort_id"] == "" then
  sort_id=0;
else
  sort_id=tonumber(args["sort_id"]);
end

local udpsql = "update t_base_organization set org_name='"..orgName.."',sort_id="..sort_id.." where 1=1 "..orgIdStr
local udpsql_res, err, errno, sqlstate = db:query(udpsql)
ngx.log(ngx.ERR,udpsql)
if not udpsql_res then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

--获取当前登录人的部门ID
local loginperson_bureau_id =tostring(ngx.var.cookie_background_bureau_id); 
local bureau_cache_sql="SELECT ORG_ID AS ID,ORG_NAME AS NAME,PARENT_ID AS PID FROM T_BASE_ORGANIZATION WHERE org_code like '%_"..loginperson_bureau_id.."_%'";

local bureau_cache_res =db:query(bureau_cache_sql);


local bureau_cache_tab = {}
for i=1,#bureau_cache_res do
	local bureau_table = {}
	bureau_table["id"] = bureau_cache_res[i]["ID"];
	bureau_table["pId"] = bureau_cache_res[i]["PID"];
	bureau_table["name"] = bureau_cache_res[i]["NAME"];
	bureau_cache_tab[i]=bureau_table;
end

redis_db:set("bureau_"..loginperson_bureau_id,cjson.encode(bureau_cache_tab));

--维护缓存结束

local returnjson = {}
returnjson.success = true
returnjson.info = "修改组织成功"
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))
















