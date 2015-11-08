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

local product_id = args["product_id"]

if product_id == nil or product_id == '' then
  ngx.say("{\"success\":false,\"info\":\"product_id不能为空\"}")
  return
end




local res = db:query("select product_name, platform_id,system_id,stage_id,subject_id,version_id from t_pro_product where product_id = "..product_id)

ngx.log(ngx.ERR, "select product_name, platform_id,system_id,stage_id,subject_id,version_id from t_pro_product where product_id = "..product_id)


if not res then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local product_info = res

local result = {};
result.success = true;
result.list = product_info;
--将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local data = cjson.encode(result);

ngx.say(data);



