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
 
 --连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end



--person_id
if args["city_id"] == nil or args["city_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"city_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数city_id不能为空！");
    return
end

local city_id = args["city_id"]


if args["rating_type"] == nil or args["rating_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_type参数错误！\"}")
  ngx.log(ngx.ERR, "ERR MSG =====> 参数rating_type不能为空！")
    return
end

local rating_type = args["rating_type"]
--local rating_type = 2

  local person_id = tostring(ngx.var.cookie_person_id)

  local shi_id = redis_db:hget("person_"..person_id.."_11","shi")

if shi_id == nil or shi_id == ngx.null then
	shi_id = redis_db:hget("person_"..person_id.."_5","shi")
end
  ngx.log(ngx.ERR,"==================================" ..person_id)
  ngx.log(ngx.ERR,"==================================" ..shi_id)
local querysql = "select  count(1) as count from t_rating_info where org_id ='"..shi_id.."' and rating_status in (2,3,5) and rating_type="..rating_type..""
local resouce_scheme = mysql_db:query(querysql)
ngx.log(ngx.ERR, querysql)

local result = {} 
local count = tonumber(resouce_scheme[1]["count"])

ngx.log(ngx.ERR,"==================================" ..tonumber(resouce_scheme[1]["count"]))
ngx.log(ngx.ERR,count > 0)
if count > 0 then
  result["success"] = true
  result["info"] = "当前登录人参加正在举行的微课大赛！"
else
	result["success"] = false
  result["info"] = "您所参加的微课大赛未开始,请确认后再报名！"
	
end



--放回连接池
mysql_db:set_keepalive(0,v_pool_size)


cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

