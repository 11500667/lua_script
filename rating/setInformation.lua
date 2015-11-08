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

--person_id
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]

--person_name,sex,mail,qq_num,poscode,addr
local updatesql = ""
local person_name = args["person_name"];
if person_name == nil or person_name == "" then
else
  updatesql =updatesql.. " person_name='"..person_name.."'"
end

local sex = args["sex"];
if sex == nil or sex == "" then
else
  updatesql =updatesql.. " ,sex='"..sex.."'"
end

local mail = args["mail"];
if mail == nil or mail == "" then
else
  updatesql =updatesql.. " ,mail='"..mail.."'"
end

local qq_num = args["qq_num"];
if qq_num == nil or qq_num == "" then
else
  updatesql =updatesql.. " ,qq_num='"..qq_num.."'"
end

local poscode = args["poscode"];
if poscode == nil or poscode == "" then
else
  updatesql =updatesql.. " ,poscode='"..poscode.."'"
end

local addr = args["addr"];
if addr == nil or addr == "" then
else
  updatesql =updatesql.. " ,addr='"..addr.."' "
end

local updatesql = "update t_dswk_login set  "..updatesql.." where person_id='"..person_id.."'"
ngx.log(ngx.ERR,updatesql)
local updatesql_res,err,errno,sqlstate = db:query(updatesql);
if not updatesql_res then
	ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
	ngx.log(ngx.ERR, "err: ".. err);
end
local returnjson = {}
returnjson["success"] = true
	returnjson["info"] = "修改成功"
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****验证短信结束**********");	