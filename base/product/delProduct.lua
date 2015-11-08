#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#胡悦 2015-06-04
#描述：删除产品
]]
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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--产品ID
if args["product_id"] == nil or args["product_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"product_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数product_id不能为空！");
    return
end

local product_id = args["product_id"]
local result = {} 
--校验产品
local res_product = mysql_db:query("SELECT count(1) as count FROM t_resource_product_scheme WHERE PRODUCT_ID ="..product_id);
ngx.log(ngx.ERR, "select count(1) as count from t_pro_product where subject_id= "..product_id)
local product_count=  tonumber(res_product[1]["count"])
if product_count > 0 then
  result["success"] = false
  result["info"] = "该产品已有版本，不能删除该产品！"
else
	local product_info = mysql_db:query("SELECT platform_id,stage_id,subject_id,system_id,version_id FROM  t_pro_product WHERE  product_id = "..product_id)
	ngx.log(ngx.ERR, "SELECT platform_id,stage_id,subject_id,system_id,version_id FROM  t_pro_product WHERE  product_id = "..product_id)
	local subject_id = ""
	local system_id=""
	local platform_id=""
	local version_id=""
	if product_info[1] == nil then
	  result["success"] = false
	  result["info"] = "product_id不存在！"
	else
		subject_id=product_info[1]["subject_id"]
		system_id =product_info[1]["system_id"]
		platform_id = product_info[1]["platform_id"]
		version_id = product_info[1]["version_id"]
		local product_key = subject_id..system_id..platform_id..version_id
		product_key = ngx.md5(product_key)
		ngx.log(ngx.ERR,"删除缓存KEY：product_" ..product_key);
		cache.del("product_"..product_key);
		mysql_db:query("delete  from t_pro_product where product_id ="..product_id)
		result["success"] = true
	end
end
--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))