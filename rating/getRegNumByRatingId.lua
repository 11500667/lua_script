#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--����ģ��
local cjson = require "cjson"

-- ��ȡ���ݿ�����
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

--����redis������
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
  ngx.log(ngx.ERR, "=====> �������ݿ�ʧ��!");
  return;
end


--����id
if args["rating_id"] == nil or args["rating_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"rating_id��������\"}")
  return
end
local rating_id = args["rating_id"]

local person_id = tostring(ngx.var.cookie_person_id)
local qu_id = redis_db:hget("person_"..person_id.."_5","qu")
local shi_id = redis_db:hget("person_"..person_id.."_5","shi")
local sheng_id=redis_db:hget("person_"..person_id.."_5","sheng")
local xiao_id=redis_db:hget("person_"..person_id.."_5","xiao")

local countsql = "select count(*) as count from t_rating_register where rating_id='"..rating_id.."';"

local count, err, errno, sqlstate = db:query(countsql)  
ngx.log(ngx.ERR,countsql)
if not count then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local count1 = count[1]["count"]

local returnjson = {}
returnjson.success = true
returnjson.count = count1

db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))




