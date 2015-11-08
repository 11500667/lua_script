#删除大赛类型 by huyue 2015-06-12
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


local status = 0

if args["rating_type_id"] == nil or args["rating_type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_type_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数rating_type_id不能为空！");
    return
end
local rating_type_id = args["rating_type_id"];

local result = {} 
local query_sql="select count(1) as count from t_rating_type where rating_type_id ="..rating_type_id

local query_res = mysql_db:query(query_sql)
ngx.log(ngx.ERR, query_sql)

local count = tonumber(query_res[1]["count"])
local result = {} 
if count > 0 then
	local update_sql="update t_rating_type set status='"..status.."' where rating_type_id="..rating_type_id
		local res,err,errno,sqlstate = mysql_db:query(update_sql)
		 ngx.log(ngx.ERR,update_sql)
		if not res then
			ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			return
		end
		local rating_type_id = res.insert_id
		result.success = true;
		result.info = "删除评比类型成功！";
else
    result["success"] = false
    result["info"] = "rating_type_id不存在！"
end	
--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))