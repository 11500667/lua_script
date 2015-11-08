#根据大赛类型ID获取大赛类型 by huyue 2015-06-12
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

local rating_type_id = args["rating_type_id"]
if rating_type_id == nil or rating_type_id == '' then
  ngx.say("{\"success\":false,\"info\":\"rating_type_id不能为空\"}")
  return
end

local res = db:query("select rating_type_id,rating_type_name,status,create_person_id from t_rating_type where rating_type_id = "..rating_type_id)

ngx.log(ngx.ERR, "select rating_type_id,rating_type_name,status,create_person_id from t_rating_type where rating_type_id = "..rating_type_id)

local rating_type_tab = {}

local result = {}
if res[1] ~= nil then
	local rating_type_res = {}
	rating_type_res["rating_type_id"] = res[1]["rating_type_id"]
	rating_type_res["rating_type_name"] = res[1]["rating_type_name"]
	rating_type_res["status"] = res[1]["status"]
	rating_type_res["create_person_id"] = res[1]["create_person_id"]
	result["list"] = rating_type_res
	result["success"] = true
  else
	result["info"] = "rating_type_id不存在"
	result["success"] = false
  
end

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))




