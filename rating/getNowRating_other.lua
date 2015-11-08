#验证当前登陆人是否是专家 by huyue 2015-06-05

--1.获得参数方法
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024*1024
}

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
  ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
  return
end

--评比ID
local rating_type = ""
if args["rating_type"] == nil or args["rating_type"] == "" then
  rating_type = 1
else
  rating_type = args["rating_type"]
end


--评比ID
local shi_id = ""
if args["shi_id"] == nil or args["shi_id"] == "" then
--默认长春市举办评比
  shi_id = "200051"
else
  shi_id = args["shi_id"]
end



local result = {}
 local rating_info
  local querysql = "SELECT id,rating_title,start_date,end_date,rating_status,huodongshuoming FROM t_rating_info WHERE rating_status in (2,3,5) and rating_type = "..rating_type..""
  rating_info = mysql_db:query(querysql)
  ngx.log(ngx.ERR,querysql)
  ngx.log(ngx.ERR,"######"..tostring(rating_info[1]).."#######")
  ngx.log(ngx.ERR,"######"..tostring(person_id).."#######")

  local ratingArray = {}
  if rating_info[1] == nil then
    result["success"] = false
    result["info"] = "当前没有正在进行的评比活动！"
  else
    for i=1,#rating_info do
      local ssdb_info = {};
      ssdb_info["rating_id"] = rating_info[i]["id"];
      ssdb_info["rating_title"] = rating_info[i]["rating_title"];
      ssdb_info["start_date"] = rating_info[i]["start_date"];
      ssdb_info["end_date"] = rating_info[i]["end_date"];
	  ssdb_info["rating_status"] = rating_info[i]["rating_status"];
	  
	  ssdb_info["file_id"] = rating_info[i]["huodongshuoming"];
      table.insert(ratingArray, ssdb_info);
    end
    result.list = ratingArray
    result.success = true
  end


cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
