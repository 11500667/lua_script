--根据bureau_id获取Subject
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

local bureau_id = args["bureau_id"]
if bureau_id == nil or bureau_id == '' then
  ngx.say("{\"success\":false,\"info\":\"bureau_id不能为空\"}")
  return
end

local edu_type_res = db:query("select  edu_type from t_base_organization where org_id = "..bureau_id)

ngx.log(ngx.ERR, "select  edu_type from t_base_organization where org_id = "..bureau_id)

local result = {} 

if edu_type_res[1] ~= nil and tostring(edu_type_res[1]["edu_type"])=='3' then 
	local stage_id=7;
	local res = db:query("select subject_id,subject_name from t_dm_subject where stage_id = "..stage_id)

	ngx.log(ngx.ERR, "select subject_id,subject_name from t_dm_subject where stage_id = "..stage_id)

	local subject_tab = {}
	for i=1,#res do
		local subject_res = {}
		subject_res["subject_id"] = res[i]["subject_id"]
		subject_res["subject_name"] = res[i]["subject_name"]
		subject_tab[i] = subject_res
	end
	result["subject_list"] = subject_tab
	result["success"] = true

else
	result["info"] = "没有此职业学校"
	result["success"] = fasle
end

db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


