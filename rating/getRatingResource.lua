#查询专家评比资源信息 by huyue 2015-06-08

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

local resource_info_id = args["resource_info_id"]
if resource_info_id == nil or resource_info_id == '' then
  ngx.say("{\"success\":false,\"info\":\"resource_info_id不能为空\"}")
  return
end

local rating_id = args["rating_id"]
if rating_id == nil or rating_id == '' then
  ngx.say("{\"success\":false,\"info\":\"rating_id不能为空\"}")
  return
end

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end


local res = db:query(" select id,rating_title,remark,scorce,ts,person_id,view_count,vote_count,comment_count  from t_rating_resource where rating_id="..rating_id.." and resource_info_id='"..resource_info_id.."'"..w_type)

ngx.log(ngx.ERR, "select id,rating_title,remark,scorce,ts,person_id  from t_rating_resource where rating_id="..rating_id.." and resource_info_id='"..resource_info_id.."'"..w_type)

local rating_resource_tab = {}
for i=1,#res do
	local rating_resource_res = {}
	rating_resource_res["id"] = res[i]["id"]
	rating_resource_res["rating_title"] = res[i]["rating_title"]
	rating_resource_res["remark"] = res[i]["remark"]
	rating_resource_res["scorce"] = res[i]["scorce"]
	rating_resource_res["ts"] = res[i]["ts"]
	rating_resource_res["person_id"] = res[i]["person_id"]
	rating_resource_res["view_count"] = res[i]["view_count"]
	rating_resource_res["vote_count"] = res[i]["vote_count"]
	rating_resource_res["comment_count"] = res[i]["comment_count"]
	rating_resource_tab[i] = rating_resource_res
end

local result = {} 
result["list"] = rating_resource_tab
result["success"] = "true"

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))





