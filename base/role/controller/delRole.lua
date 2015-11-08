--删除角色 by huyue 2015-08-04
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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--角色ID
if args["role_id"] == nil or args["role_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"role_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数role_id不能为空！");
    return
end

local role_id=args["role_id"];

local update_role_sql = "update t_sys_role set b_use=0 where role_id="..role_id;
ngx.log(ngx.ERR,"role_log------------>"..update_role_sql);

local update_role_res,err,errno,sqlstate = mysql_db:query(update_role_sql);

if not update_role_res then
	ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
local result = {} 
result.success = true;
result.info = "删除角色成功！";
ngx.print(cjson.encode(result));

