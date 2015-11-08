#ngx.header.content_type = "text/plain;charset=utf-8"
--学校审核学生
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

--学校id
if args["student_id"] == nil or args["student_id"] == "" then
  ngx.print("{\"success\":false,\"info\":\"student_id参数错误！\"}")
  return
end
local student_id = args["student_id"]
--审核状态
if args["audit_status"] == nil or args["audit_status"] == "" then
  ngx.print("{\"success\":false,\"info\":\"audit_status参数错误！\"}")
  return
end
local audit_status = args["audit_status"]



local school_open_register, err, errno, sqlstate = db:query("UPDATE  t_base_student SET b_use = \'"..audit_status.."\'  WHERE  student_id = \'"..student_id.."\';")
ngx.log(ngx.ERR,"UPDATE  t_base_student SET b_use = \'"..audit_status.."\'  WHERE  student_id = \'"..student_id.."\';")
if not school_open_register then

  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local school_open_register, err, errno, sqlstate = db:query("UPDATE  t_sys_loginperson SET audit_status = \'"..audit_status.."\'  WHERE  person_id = \'"..student_id.."\' and identity_id = 6;")
ngx.log(ngx.ERR,"UPDATE  t_sys_loginperson SET audit_status = \'"..audit_status.."\'  WHERE  person_id = \'"..student_id.."\' and identity_id = 6;")
if not school_open_register then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
--设置学生状态到缓存
local loginname, err, errno, sqlstate = db:query("select login_name from t_sys_loginperson where identity_id = 6 and person_id = "..student_id..";")
local login_name = loginname[1]["login_name"]
local setLoginResult = redis_db: hmset("login_" ..login_name,"audit_status",audit_status )




--返回值
local returnjson = {}
returnjson.success = true

db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))
