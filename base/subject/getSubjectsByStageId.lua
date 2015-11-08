#通过学段ID获取学科信息，by hy 2015-06-05
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

local stage_id = args["stage_id"]
if stage_id == nil or stage_id == '' then
  ngx.say("{\"success\":false,\"info\":\"stage_id不能为空\"}")
  return
end

local res = db:query("select subject_id,subject_name from t_dm_subject where stage_id = "..stage_id)

ngx.log(ngx.ERR, "select subject_id,subject_name from t_dm_subject where stage_id = "..stage_id)

local subject_tab = {}
for i=1,#res do
	local subject_res = {}
	subject_res["subject_id"] = res[i]["subject_id"]
	subject_res["subject_name"] = res[i]["subject_name"]

	subject_tab[i] = subject_res
end

local result = {} 
result["list"] = subject_tab
result["success"] = "true"

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))




