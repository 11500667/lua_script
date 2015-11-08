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

--org_id    2000963
if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return
end
local org_id = args["org_id"]

--person_id   100001
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]

ngx.log(ngx.ERR, "**********东师理想微课大赛*****报名前查询人员信息开始**********");	

local querysql = "SELECT tdl.person_id,tdl.person_name , tdl.login_name , tdl.login_password ,tdl.identity_id , tdl.b_use , tdl.sex , tdl.tel , tdl.mail , tdl.qq_num, tdl.poscode, tdl.addr, tdl.org_id, tdl.stage, tdl.subject,    ( SELECT org_name FROM t_base_organization WHERE ORG_ID="..org_id.." UNION ALL SELECT org_name FROM t_dswk_organization WHERE ORG_ID="..org_id..") AS org_name, ( SELECT province_id FROM t_base_organization WHERE ORG_ID="..org_id.." UNION ALL SELECT province_id FROM t_dswk_organization WHERE ORG_ID="..org_id..") AS province_id, ( SELECT city_id FROM t_base_organization WHERE ORG_ID="..org_id.." UNION ALL SELECT city_id FROM t_dswk_organization WHERE ORG_ID="..org_id..") AS city_id, ( SELECT district_id FROM t_base_organization WHERE ORG_ID="..org_id.." UNION ALL SELECT district_id FROM t_dswk_organization WHERE ORG_ID="..org_id..") AS district_id,tds.stage_name,tdj.subject_name FROM t_dswk_login tdl,t_dm_stage tds,t_dm_subject tdj WHERE tdl.person_id="..person_id.." and tdl.stage=tds.stage_id and tdl.subject=tdj.subject_id AND identity_id=1;"

ngx.log(ngx.ERR,querysql)
local querysql_res,err,errno,sqlstate=db:query(querysql)
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  return
end

local returnjson = {}
returnjson.person_id     =  querysql_res[1]["person_id"]     
returnjson.person_name   =  querysql_res[1]["person_name"]   
returnjson.login_name    =  querysql_res[1]["login_name"]    
returnjson.login_password=  querysql_res[1]["login_password"]
returnjson.identity_id   =  querysql_res[1]["identity_id"]   
returnjson.b_use         =  querysql_res[1]["b_use"]         
returnjson.sex           =  querysql_res[1]["sex"]           
returnjson.tel           =  querysql_res[1]["tel"]           
returnjson.mail          =  querysql_res[1]["mail"]          
returnjson.qq_num        =  querysql_res[1]["qq_num"]        
returnjson.poscode       =  querysql_res[1]["poscode"]       
returnjson.addr          =  querysql_res[1]["addr"]          
returnjson.org_id        =  querysql_res[1]["org_id"]        
returnjson.stage         =  querysql_res[1]["stage"]         
returnjson.subject       =  querysql_res[1]["subject"]       
returnjson.org_name      =  querysql_res[1]["org_name"]      
returnjson.province_id   =  querysql_res[1]["province_id"]   
returnjson.city_id       =  querysql_res[1]["city_id"]       
returnjson.district_id   =  querysql_res[1]["district_id"]   
returnjson.stage_name    =  querysql_res[1]["stage_name"]    
returnjson.subject_name  =  querysql_res[1]["subject_name"]  
  local province_info = db:query("SELECT provincename FROM  t_gov_province WHERE  id = "..querysql_res[1]["province_id"]   .." ")
  returnjson.province_name= province_info[1]["provincename"]
  local city_info = db:query("SELECT cityname FROM  t_gov_city WHERE  id = "..querysql_res[1]["city_id"].." ")
  returnjson.city_name = city_info[1]["cityname"]
  local district_info = db:query("SELECT districtname FROM  t_gov_district WHERE  id = "..querysql_res[1]["district_id"].." ")
  returnjson.district_name = district_info[1]["districtname"]
returnjson["success"] = true
returnjson["info"] = "验证成功"
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))
ngx.log(ngx.ERR, "**********东师理想微课大赛*****报名前查询人员信息结束**********");	
