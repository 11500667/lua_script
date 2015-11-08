--判断一个学校是否为主校

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
	--org_id = tostring(ngx.var.cookie_background_bureau_id);
	ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数org_id不能为空！");
    return
else
  org_id = args["org_id"]

end

local query_sql = "SELECT count(1) as count FROM T_BASE_ORGANIZATION WHERE MAIN_SCHOOL_ID in("..org_id..")";


ngx.log(ngx.ERR,"org_log----------->"..query_sql);

local query_res = mysql_db:query(query_sql);

local count = tonumber(query_res[1]["count"])
local result = {} 

if count > 0 then
  result["success"] = true
  result["result"] = true
  result["info"] = "当前学校存在分校！"
else
	result["success"] = true
	result["result"] = false
	result["info"] = "当前学校不存在分校！"
	
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))