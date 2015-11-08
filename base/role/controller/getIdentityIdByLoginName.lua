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
if args["login_name"] == nil or args["login_name"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"login_name参数错误！\"}");
  return;
end
local login_name = args["login_name"];

local sql="select IDENTITY_ID from dsideal_db.t_sys_loginperson where login_name = '"..login_name.."'";
ngx.log(ngx.ERR,sql);
local res = db:query(sql);
if not res then
  return;
end
local identity_id = res[1]["IDENTITY_ID"];

local result={};
result["IDENTITY_ID"]=identity_id;

db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);

ngx.print(cjson.encode(result))