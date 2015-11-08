--获取角色树 by huyue 2015-07-28
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
cjson.encode_empty_table_as_object(false);
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


local role_tab = {}
local m=1;
local temp={};
	temp["name"]="所有角色";
	temp["id"]=0;
	temp["pId"]=-1;
	temp["open"]=true;
	role_tab[m]=temp;
	m=m+1;


local query_identity_sql = "select identity_id,identity_name  from t_sys_identity order by sort_id desc";
ngx.log(ngx.ERR,"role_log----------->"..query_identity_sql);

local query_identity_res = mysql_db:query(query_identity_sql);

for i=1,#query_identity_res do
	local identity_res = {}
	identity_res["name"]=query_identity_res[i]["identity_name"];
	identity_res["id"]="identity"..query_identity_res[i]["identity_id"];
	identity_res["pId"]=0;
	identity_res["open"]=false;
	role_tab[m]=identity_res;
	m=m+1;
end

local query_role_sql="select role_id,role_name,identity_id,role_code from t_sys_role where b_use=1";

ngx.log(ngx.ERR,"role_log----------->"..query_role_sql);
local query_role_res = mysql_db:query(query_role_sql);

for i=1,#query_role_res do
	local role_res = {}
	role_res["name"]=query_role_res[i]["role_name"];
	role_res["id"]=query_role_res[i]["role_id"];
	role_res["pId"]="identity"..query_role_res[i]["identity_id"];
	role_res["role_code"]=query_role_res[i]["role_code"];
	role_res["open"]=false;
	role_tab[m]=role_res;
	m=m+1;
end


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["table_List"] = role_tab
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))