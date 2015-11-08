#验证当前登陆人是否是专家 by huyue 2015-06-05

--1.获得参数方法
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
local mysql_db, err = mysql : new();
if not mysql_db then
  ngx.log(ngx.ERR, err);
  return;
end

mysql_db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = mysql_db:connect{
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



--person_id
if args["login_id"] == nil or args["login_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"login_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数login_id不能为空！");
    return
end

local login_id = args["login_id"]


local resouce_scheme = mysql_db:query("select  count(1) as count from t_rating_experts where person_id ='"..login_id.."'")

ngx.log(ngx.ERR, "select  count(1) as count from t_rating_experts where person_id ="..login_id.."'")

local result = {} 
local count = tonumber(resouce_scheme[1]["count"])


if count > 0 then
  result["success"] = true
  result["info"] = "当前登录人是专家！"
else
	result["success"] = false
  result["info"] = "当前登录人不是专家！"
	
end



--放回连接池
mysql_db:set_keepalive(0,v_pool_size)


cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

