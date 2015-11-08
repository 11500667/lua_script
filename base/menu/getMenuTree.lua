#获取菜单树 by huyue 2015-07-11


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



local query_sql = "SELECT MENU_ID,MENU_NAME,PARENT_ID,MENU_CODE FROM  T_SYS_MENU  ORDER BY SORT_ID";
ngx.log(ngx.ERR,"menu_log----------->"..query_sql);

local query_res = mysql_db:query(query_sql);


local menu_tab = {}
for i=1,#query_res do
	local menu_res = {}
	menu_res["id"] = query_res[i]["MENU_ID"]
	menu_res["name"] = query_res[i]["MENU_NAME"]
	menu_res["pId"] = query_res[i]["PARENT_ID"]
	menu_res["open"] = false;
	menu_res["menu_code"] = query_res[i]["MENU_CODE"]
	menu_tab[i] = menu_res
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["table_List"] = menu_tab

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
