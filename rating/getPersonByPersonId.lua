--根据人员ID获取该人员属性
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
  args = ngx.req.get_uri_args();
else
  ngx.req.read_body();
  args = ngx.req.get_post_args();
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

local person_id = args["person_id"]
if person_id == nil or person_id == '' then
  ngx.say("{\"success\":false,\"info\":\"person_id不能为空\"}")
  return
end

local rating_info = db:query("SELECT email,bureau_id,avatar_url,avatar_name,tel,maladdr,org_id,person_name,xb_name,province_id,city_id,district_id,stage_id,subject_id FROM  t_base_person WHERE  person_id = "..person_id.." AND b_use=1")

ngx.log(ngx.ERR, "SELECT person_name,  xb_name,province_id,city_id,district_id,stage_id,subject_id FROM  t_base_person WHERE  person_id = "..person_id.." AND b_use=1")

local result = {} 

if rating_info[1] == nil then
  result["success"] = false
  result["info"] = "person_id不存在！"
else
  result["success"] = true
  result["person_name"] = rating_info[1]["person_name"]
  result["xb_name"] = rating_info[1]["xb_name"]
  
  result["province_id"] = rating_info[1]["province_id"]
  local province_info = db:query("SELECT provincename FROM  t_gov_province WHERE  id = "..rating_info[1]["province_id"].." ")
  result["province_name"] = province_info[1]["provincename"]
  
  result["city_id"] = rating_info[1]["city_id"]
  local city_info = db:query("SELECT cityname FROM  t_gov_city WHERE  id = "..rating_info[1]["city_id"].." ")
  result["city_name"] = city_info[1]["cityname"]
  
  result["district_id"] = rating_info[1]["district_id"]
  local district_info = db:query("SELECT districtname FROM  t_gov_district WHERE  id = "..rating_info[1]["district_id"].." ")
  result["district_name"] = district_info[1]["districtname"]
  
  result["stage_id"] = rating_info[1]["stage_id"]
  local stage_info = db:query("SELECT stage_name FROM   t_dm_stage WHERE  STAGE_ID = "..rating_info[1]["stage_id"].." ")
  result["stage_name"] = stage_info[1]["stage_name"]
  
  result["subject_id"] = rating_info[1]["subject_id"]
  local subject_info = db:query("SELECT subject_name FROM   t_dm_subject WHERE  SUBJECT_ID = "..rating_info[1]["subject_id"].." ")
  result["subject_name"] = subject_info[1]["subject_name"]
  
  result["school_id"] = rating_info[1]["bureau_id"]
  local school_info = db:query("SELECT org_name FROM   t_base_organization where  org_id = "..rating_info[1]["bureau_id"].." ")
  ngx.log(ngx.ERR, "SELECT org_name FROM   t_base_organization where  org_id = "..rating_info[1]["bureau_id"].." ");
  result["school_name"] = school_info[1]["org_name"]
  
  result["tel"] = rating_info[1]["tel"]
  result["email"] = rating_info[1]["email"]
  result["avatar_url"] = rating_info[1]["avatar_url"]
  result["avatar_name"] = rating_info[1]["avatar_name"]

end

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))



