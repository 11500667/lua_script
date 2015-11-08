#根据组织ID获取组织树

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


local org_id = args["org_id"];

if args["org_id"] == nil or args["org_id"] == "" then
	org_id = tostring(ngx.var.cookie_background_bureau_id);
else
  org_id = args["org_id"]

end

local query_sql = "SELECT ORG_ID ,ORG_NAME,PARENT_ID ,ORG_CODE,SORT_ID FROM T_BASE_ORGANIZATION WHERE ORG_CODE like'%/_"..org_id.."/_%'  escape '/' order by sort_id";
ngx.log(ngx.ERR,"org_log----------->"..query_sql);

local query_res = mysql_db:query(query_sql);

local org_tab = {}
for i=1,#query_res do
	local org_res = {}
	org_res["id"] = query_res[i]["ORG_ID"]
	org_res["name"] = query_res[i]["ORG_NAME"]
	org_res["pId"] = query_res[i]["PARENT_ID"]
	org_res["open"] = true;
	org_res["org_code"] = query_res[i]["ORG_CODE"]
	org_res["sort_id"] = query_res[i]["SORT_ID"]
	if tonumber(query_res[i]["ORG_ID"]) == tonumber(org_id) then
	
		org_res["noRemoveBtn"] = true;
		org_res["noEditBtn"] = true;

	end
	org_tab[i] = org_res
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["table_List"] = org_tab

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))