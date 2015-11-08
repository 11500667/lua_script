#新增参赛类型 by huyue 2015-06-12
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


if args["rating_type_name"] == nil or args["rating_type_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_type_name参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数rating_type_name不能为空！");
    return
end
local rating_type_name = tostring(args["rating_type_name"]);

local status = 1

local person_id = tostring(ngx.var.cookie_background_person_id)

--校验是否可以新增

local query_sql="select count(1) as count from t_rating_type where status=1 and rating_type_name ='"..rating_type_name.."'"

local query_res = mysql_db:query(query_sql)
ngx.log(ngx.ERR, query_sql)

local count = tonumber(query_res[1]["count"])
local result = {} 
if count > 0 then
  result["success"] = false
  result["info"] = "该评比类型已存在，不能添加！" 
 else
	--插入评比类型到数据库
	local insert_sql="insert into t_rating_type(rating_type_name,status,create_person_id) values ('"..rating_type_name.."',"..status..","..person_id..");"

	local res,err,errno,sqlstate = mysql_db:query(insert_sql)

	 ngx.log(ngx.ERR,insert_sql)

	if not res then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
	end
	 
	local rating_type_id = res.insert_id
		result.success = true;
	result.info = "新增评比类型成功！";
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))