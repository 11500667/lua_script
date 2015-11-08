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

--WKDS_ID_INT
if args["wkds_id_int"] == nil or args["wkds_id_int"] == "" then
  ngx.say("{\"success\":false,\"info\":\"wkds_id_int参数错误！\"}")
  return
end
local wkds_id_int = args["wkds_id_int"]


--person_id
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]

--dis_type
if args["dis_type"] == nil or args["dis_type"] == "" then
  ngx.say("{\"success\":false,\"info\":\"dis_type参数错误！\"}")
  return
end
local dis_type = args["dis_type"]

--re_type
if args["re_type"] == nil or args["re_type"] == "" then
  ngx.say("{\"success\":false,\"info\":\"re_type参数错误！\"}")
  return
end
local re_type = args["re_type"]

--re_type
if args["wk_id"] == nil or args["wk_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"wk_id参数错误！\"}")
  return
end
local wk_id = args["wk_id"]


if(person_id == nil or person_id == "" or person_id==ngx.null  or person_id == "nil") then
	ngx.say("{\"success\":false,\"info\":\"person_id不存在！\"}")
	return
end

local countsql = "select count(*) as count from t_his_wk where wkds_id_int = "..wkds_id_int.." and person_id="..person_id..";"
local count_wk, err, errno, sqlstate = db:query(countsql)
ngx.log(ngx.ERR,countsql)
if not count_wk then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local returnjson = {}

local count = count_wk[1]["count"];
local querysql = ""
if tonumber(count) == 0 then
querysql = "insert into t_his_wk (wk_id,PERSON_ID , WKDS_ID_INT ,CREATE_TIME ,UPDATE_TIME,TIMES,RE_TYPE,DIS_TYPE ) VALUES  ("..wk_id..","..person_id..","..wkds_id_int..",now(),now(),0,"..re_type..","..dis_type..")"
returnjson.info="第一次浏览，插入"
else
querysql = "update  t_his_wk set  UPDATE_TIME=now(), TIMES = TIMES+1,re_type = "..re_type.." , dis_type = "..dis_type.." ,wk_id="..wk_id.."   where wkds_id_int = "..wkds_id_int.." and person_id="..person_id..";"
returnjson.info="重复浏览，更新"
end
local wk, err, errno, sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not wk then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


cjson.encode_empty_table_as_object(false)
returnjson.success = true
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))