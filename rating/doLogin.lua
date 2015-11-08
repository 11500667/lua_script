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

--登录名
local login_name_str =""
if args["login_name"] == nil or args["login_name"] == "" then
  ngx.say("{\"success\":false,\"info\":\"login_name参数错误！\"}")
  return
else
  login_name_str = "and login_name = '"..args["login_name"].."' "
end
local login_name = args["login_name"]


--登录密码
local login_password_str = ""
if args["login_password"] == nil or args["login_password"] == "" then
  ngx.say("{\"success\":false,\"info\":\"login_password参数错误！\"}")
  return
else
  login_password_str = "and login_password = '"..ngx.md5(tostring(args["login_password"])).."'"
end
local login_password = ngx.md5(tostring(args["login_password"]))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****登录开始**********");

--type
local type_str = ""
if args["type"] == nil or args["type"] == "" then
  ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
  return
else
  type_str = " and identity_id= "..args["type"]
end
local type_no = args["type"]

local countsql = "select count(*) as count from t_dswk_login where 1=1 "..login_name_str..login_password_str..type_str
ngx.log(ngx.ERR,countsql)
local countsql_res,err,errno,sqlstatus = db:query(countsql)
if not countsql_res then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local querysql = ""
local querysql_res = ""
local returnjson = {}
if tonumber(countsql_res[1]["count"]) == 0 then
  querysql = "select tsl.person_id,tsl.person_name,tsl.login_name,tsl.login_password,tsl.identity_id,tre.stage_id,tre.subject_id from t_rating_experts tre,t_sys_loginperson tsl where tre.login_id=tsl.login_name and tre.login_id='"..login_name.."' and tsl.login_name='"..login_name.."' and tre.login_pwd='"..login_password.."' "
  querysql_res,err,errno,sqlstate = db:query(querysql);
  ngx.log(ngx.ERR,querysql)
  if not querysql_res then
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
  if querysql_res[1] == nil then
    ngx.say("{\"success\":false,\"info\":\"您输入的账号或密码不正确，请重新输入！\"}")
    return
  end
  returnjson.stage_id = querysql_res[1]["stage_id"]
  returnjson.subject_id = querysql_res[1]["subject_id"]
else
  querysql = "select person_id,person_name,login_name,login_password,identity_id,b_use,sex,tel,mail,qq_num,poscode,addr,org_id,stage,subject from t_dswk_login where 1=1 "..login_name_str..login_password_str..type_str

  querysql_res,err,errno,sqlstate = db:query(querysql);
  ngx.log(ngx.ERR,querysql)
  if not querysql_res then
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
  if querysql_res[1] == nil then
    ngx.say("{\"success\":false,\"info\":\"您输入的账号或密码不正确，请重新输入！\"}")
    return
  end

  returnjson.b_use = querysql_res[1]["b_use"]
  returnjson.sex = querysql_res[1]["sex"]
  returnjson.tel = querysql_res[1]["tel"]
  returnjson.mail = querysql_res[1]["mail"]
  returnjson.qq_num = querysql_res[1]["qq_num"]
  returnjson.poscode = querysql_res[1]["poscode"]
  returnjson.addr = querysql_res[1]["addr"]
  returnjson.org_id = querysql_res[1]["org_id"]


end
  --0后台  1前台
  returnjson.background_login = type_no
returnjson.person_id = querysql_res[1]["person_id"]
returnjson.person_name = querysql_res[1]["person_name"]
returnjson.login_name = querysql_res[1]["login_name"]
returnjson.login_password = querysql_res[1]["login_password"]
returnjson.identity_id = querysql_res[1]["identity_id"]
returnjson.stage = querysql_res[1]["stage"]
returnjson.subject = querysql_res[1]["subject"]
returnjson.success = true
returnjson.info = "登录成功"
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****登录结束**********");
