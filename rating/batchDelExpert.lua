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

--exp_id
if args["exp_id"] == nil or args["exp_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"exp_id参数错误！\"}")
  return
end
local exp_id = args["exp_id"]


function split(s, delim)
  if type(delim) ~= "string" or string.len(delim) <= 0 then
    return
  end

  local start = 1
  local t = {}
  while true do
    local pos = string.find (s, delim, start, true) -- plain find
    if not pos then
      break
    end

    table.insert (t, string.sub (s, start, pos - 1))
    start = pos + string.len (delim)
  end
  table.insert (t, string.sub (s, start))

  return t
end

local del_id = split(exp_id,",")
ngx.log(ngx.ERR,del_id[1]) 
for i=1, #del_id do
  local exp_delId = del_id[i]
  local querysql = "select login_id from t_rating_experts where id="..exp_delId..""
  local querysql_res, err, errno, sqlstate = db:query(querysql)
  ngx.log(ngx.ERR,querysql)
  if not querysql_res then
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
 
    local login_id = querysql_res[1]["login_id"]
	ngx.log(ngx.ERR,login_id)
    local result = redis_db: del("login_" ..login_id)
  
end


local delSql = "delete  from  t_rating_experts where id in ("..exp_id..")"
local ex, err, errno, sqlstate = db:query(delSql)
ngx.log(ngx.ERR,delSql)
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







