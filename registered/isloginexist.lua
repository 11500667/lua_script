ngx.log(ngx.ERR,"判断用户名是否存在")
--获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
  args = ngx.req.get_uri_args();
else
  ngx.req.read_body();
  args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--login_name用户名
if args["login_name"] == nil or args["login_name"] == "" then
  ngx.print("{\"success\":false,\"info\":\"login_name参数错误！\"}")
  return
end
local login_name = args["login_name"]
ngx.log(ngx.ERR, login_name)

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

local res, err, errno, sqlstate = db:query("SELECT count(*) as count from t_sys_loginperson where login_name = '"..login_name.."';")
ngx.log(ngx.ERR,"SELECT count(*) as count from t_sys_loginperson where login_name = '"..login_name.."';")
if not res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local totalRow = res[1]["count"]

local returnjson = {}
returnjson["totalRow"] = totalRow
if totalRow ~= "0" then
returnjson["success"] = false
else
returnjson["success"] = true
end
cjson.encode_empty_table_as_object(false)

db: set_keepalive(0, v_pool_size)

ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))