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

--person_name
if args["person_name"] == nil or args["person_name"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_name参数错误！\"}")
  return
end
local person_name = args["person_name"]

--login_name
if args["login_name"] == nil or args["login_name"] == "" then
  ngx.say("{\"success\":false,\"info\":\"login_name参数错误！\"}")
  return
end
local login_name = args["login_name"]

--login_password
if args["login_password"] == nil or args["login_password"] == "" then
  ngx.say("{\"success\":false,\"info\":\"login_password参数错误！\"}")
  return
end
local login_password = args["login_password"]

--sex
if args["sex"] == nil or args["sex"] == "" then
  ngx.say("{\"success\":false,\"info\":\"sex参数错误！\"}")
  return
end
local sex = args["sex"]

--tel
if args["tel"] == nil or args["tel"] == "" then
  ngx.say("{\"success\":false,\"info\":\"tel参数错误！\"}")
  return
end
local tel = args["tel"]

--mail
if args["mail"] == nil or args["mail"] == "" then
  ngx.say("{\"success\":false,\"info\":\"mail参数错误！\"}")
  return
end
local mail = args["mail"]

--qq_num
if args["qq_num"] == nil or args["qq_num"] == "" then
  ngx.say("{\"success\":false,\"info\":\"qq_num参数错误！\"}")
  return
end
local qq_num = args["qq_num"]

--poscode
if args["poscode"] == nil or args["poscode"] == "" then
  ngx.say("{\"success\":false,\"info\":\"poscode参数错误！\"}")
  return
end
local poscode = args["poscode"]

--addr
if args["addr"] == nil or args["addr"] == "" then
  ngx.say("{\"success\":false,\"info\":\"addr参数错误！\"}")
  return
end
local addr = args["addr"]

--org_id
if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return
end
local org_id = args["org_id"]

--stage
if args["stage"] == nil or args["stage"] == "" then
  ngx.say("{\"success\":false,\"info\":\"stage参数错误！\"}")
  return
end
local stage = args["stage"]

--subject
if args["subject"] == nil or args["subject"] == "" then
  ngx.say("{\"success\":false,\"info\":\"subject参数错误！\"}")
  return
end
local subject = args["subject"]

ngx.log(ngx.ERR, "**********东师理想微课大赛*****注册开始**********");	

local inssql = "insert into t_dswk_login (STAGE,SUBJECT,PERSON_NAME, LOGIN_NAME, LOGIN_PASSWORD, IDENTITY_ID, B_USE, SEX, TEL, MAIL, QQ_NUM, POSCODE, ADDR, ORG_ID) values ( '"..stage.."', '"..subject.."', '"..person_name.."', '"..login_name.."', '"..ngx.md5(tostring(args["login_password"])).."', 1, 1, '"..sex.."', '"..tel.."', '"..mail.."', '"..qq_num.."', '"..poscode.."', '"..addr.."', "..org_id..");"
ngx.log(ngx.ERR,inssql)
local inssql_res,err,errno,sqlstate = db:query(inssql)
--[[
local inssql_res,err,errno,sqlstate = db:query(inssql)

if not inssql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  return	
end
]] 


local returnjson = {}
returnjson["success"] = true
returnjson["info"] = "验证成功"
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))


ngx.log(ngx.ERR, "**********东师理想微课大赛*****注册结束**********");	













