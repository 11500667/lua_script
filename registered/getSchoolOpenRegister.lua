#ngx.header.content_type = "text/plain;charset=utf-8"

--根据学校ID获取该学校的注册状态
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
  ngx.log(ngx.ERR,"failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--school_id参数
if args["school_id"] == nil or args["school_id"] == "" then
  ngx.print("{\"success\":false,\"info\":\"school_id参数错误！\"}")
  return
end
local school_id = args["school_id"]
ngx.log(ngx.ERR, school_id)


local school_open_register, err, errno, sqlstate = db:query("SELECT open_register,org_id,org_name FROM t_base_organization WHERE org_id = \'"..school_id.."\';  ")
ngx.log(ngx.ERR,"SELECT open_register FROM t_base_organization WHERE org_id = \'"..school_id.."\';  ")
if not school_open_register then
  ngx.log(ngx.ERR,"{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


ngx.log(ngx.ERR,"SELECT open_register,org_id,org_name FROM t_base_organization WHERE org_id = \'"..school_id.."\';  ")

--返回值
local returnjson = {}
returnjson.success = true
returnjson.open_register = school_open_register[1]["open_register"]
returnjson.org_id = school_open_register[1]["org_id"]
returnjson.org_name = school_open_register[1]["org_name"]
cjson.encode_empty_table_as_object(false)
ngx.log(ngx.ERR,cjson.encode(returnjson))

db: set_keepalive(0, v_pool_size)

ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))
