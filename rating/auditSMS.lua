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

--tel
if args["tel"] == nil or args["tel"] == "" then
  ngx.say("{\"success\":false,\"info\":\"tel参数错误！\"}")
  return
end
local tel = args["tel"]

--type
if args["type"] == nil or args["type"] == "" then
  ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
  return
end
local type_no = args["type"]

--verification_code
if args["verification_code"] == nil or args["verification_code"] == "" then
  ngx.say("{\"success\":false,\"info\":\"verification_code参数错误！\"}")
  return
end
local verification_code = args["verification_code"]

ngx.log(ngx.ERR, "**********东师理想微课大赛*****验证短信开始**********");	
--[[
local querysql = "select verification_code from t_base_sendsms where tel='"..tel.."' and type="..type_no.." order by id desc limit 0,1"
ngx.log(ngx.ERR,querysql)
local querysql_res ,err,errno,sqlstate = db:query(querysql)
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  return
end ]]
local audit_no = redis_db:get(tel)
--local verification_code = querysql_res[1]["verification_code"]
ngx.log(ngx.ERR,"*****验证码信息*****")
ngx.log(ngx.ERR,audit_no)
ngx.log(ngx.ERR,verification_code)

if audit_no == ngx.null then
  ngx.say("{\"success\":false,\"info\":\"验证码已失效,请重新发送！\"}");
  return	
end

local returnjson = {}
returnjson["success"] = false
returnjson["info"] = "验证失败"
if audit_no == verification_code then
	returnjson["success"] = true
	returnjson["info"] = "验证成功"
end
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****验证短信结束**********");	




















