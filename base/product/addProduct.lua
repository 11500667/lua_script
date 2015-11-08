#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#胡悦 2015-06-04
#描述：新增产品
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

--产品名称
if args["product_name"] == nil or args["product_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"product_name参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数product_name不能为空！");
    return
end
local product_name = tostring(args["product_name"]);

--平台ID
if args["platform_id"] == nil or args["platform_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"platform_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数platform_id不能为空！");
    return
end
local platform_id = args["platform_id"];

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数stage_id不能为空！");
    return
end
local stage_id = args["stage_id"];

--学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数subject_id不能为空！");
    return
end
local subject_id = args["subject_id"];

--系统ID
if args["system_id"] == nil or args["system_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"system_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数system_id不能为空！");
    return
end
local system_id = args["system_id"];

--版本ID
if args["version_id"] == nil or args["version_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数version_id不能为空！");
    return
end
local version_id = args["version_id"];

--新增产品校验开始
local query_sql="select count(1) as count from t_pro_product where subject_id ="..subject_id.." and system_id="..system_id.." and platform_id="..platform_id.." and version_id="..version_id

local query_res = mysql_db:query(query_sql)
ngx.log(ngx.ERR, query_sql)

local count = tonumber(query_res[1]["count"])
--新增产品校验结束
local result = {} 
if count > 0 then
  result["success"] = false
  result["info"] = "此产品已存在，不能添加！" 
 else
 	
	 local insert_sql="insert into t_pro_product(product_name,platform_id,stage_id,subject_id,system_id,version_id) values ('"..product_name.."',"..platform_id..","..stage_id..","..subject_id..","..system_id..","..version_id..");"

	--insert_sql = ngx.quote_sql_str(insert_sql);
	--ngx.say("防止sql注入："..raw_value..'       :'..insert_sql);

	local res,err,errno,sqlstate = mysql_db:query(insert_sql)

	 ngx.log(ngx.ERR,insert_sql)

	if not res then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
	end
	 
	local product_id = res.insert_id

	local product_key = subject_id..system_id..platform_id..version_id
	product_key = ngx.md5(product_key)

	ngx.log(ngx.ERR,"放入缓存KEY：product_" ..product_key);
	cache:set("product_"..product_key,product_id);
	result["success"] = true
	
  end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)



cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))