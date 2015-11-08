#ngx.header.content_type = "text/plain;charset=utf-8"

--在 t_base_organization 表中增加 open_register 字段，默认值为1，注释：1.开放注册 0.关闭注册
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

--学校id
local schoool_id = args["school_id"]

local flag

if schoool_id == "nil" or string.len(schoool_id) == 0  then
  ngx.say("{\"success\":false,\"info\":\"schoolId不能为空\"}")
  return
end


if  args["flag"] == "nil" or string.len( args["flag"]) == 0  then
  flag = "1"
else
  flag=args["flag"]

end

local school_open_register, err, errno, sqlstate = db:query("UPDATE t_base_organization SET open_register = \'"..flag.."\'  WHERE  org_id = \'"..schoool_id.."\';  ")
ngx.log(ngx.ERR,"UPDATE t_base_organization SET open_register = \'"..flag.."\'  WHERE  org_id = \'"..schoool_id.."\';  ")
if not school_open_register then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end



--返回值
local returnjson = {}
returnjson.success = true

db: set_keepalive(0, v_pool_size)

ngx.log(ngx.ERR, cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))
