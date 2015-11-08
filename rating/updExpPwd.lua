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

--local rnd = require("rnd")

--function getrnd()
--	return math.random(0,100)
--end
math.random(100000,999999)

local querysql = "select id,login_id from t_rating_experts where rating_id="..rating_id.." "
local exp_id, err, errno, sqlstate = db:query(querysql)
	ngx.log(ngx.ERR,querysql)
	if not exp_id then
	ngx.log(ngx.ERR, "err: ".. err);
	return
	end

for i=1,#exp_id do
	local pwd_rel = tostring(math.random(100000,999999))
	local pwd_new= ngx.md5(pwd_rel)
	ngx.log(ngx.ERR, "err: ".. pwd_new);
	local id = exp_id[i]["id"];
	local login_id = exp_id[i]["login_id"];
	local upd_id = "update t_rating_experts set login_pwd='"..pwd_new.."',login_pwd_rel='"..pwd_rel.."' where id="..id..";"
	local ex, err, errno, sqlstate = db:query(upd_id)
	ngx.log(ngx.ERR,upd_id)
	if not ex then
		ngx.log(ngx.ERR, "err: ".. err);
	return
	end
	local setLoginResult = redis_db: hset("login_" ..login_id, "pwd",pwd_new)
	ngx.log(ngx.ERR, "login_" ..login_id, "pwd",pwd_new);
	
end

local returnjson = {}
returnjson.success = true
returnjson.info = "批量修改密码成功"
cjson.encode_empty_table_as_object(false)


db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)

ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))












