#获取大赛类型 by huyue 2015-06-12
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

  
local person_id = tostring(ngx.var.cookie_background_person_id)
  
  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
ngx.log(ngx.ERR,"select rating_type_id,rating_type_name,status,create_person_id,group_type from t_rating_type where status =1 and CREATE_PERSON_ID like %"..person_id.."%  LIMIT "..offset..","..limit)
local res = db:query("select rating_type_id,rating_type_name,status,create_person_id,group_type from t_rating_type where status =1 and CREATE_PERSON_ID like '%"..person_id.."%'  LIMIT "..offset..","..limit);

local res_count = db:query("select count(1) as count from t_rating_type where status =1  ");
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

ngx.log(ngx.ERR, "select rating_type_id,rating_type_name,status,create_person_id,group_type from t_rating_type where status =1 and CREATE_PERSON_ID like %"..person_id.."%  LIMIT "..offset..","..limit);

local rating_type_tab = {}
for i=1,#res do
	local rating_type_res = {}
	rating_type_res["rating_type_id"] = res[i]["rating_type_id"]
	rating_type_res["rating_type_name"] = res[i]["rating_type_name"]
	rating_type_res["status"] = res[i]["status"]
	rating_type_res["create_person_id"] = res[i]["create_person_id"]
	rating_type_res["group_type"] = res[i]["group_type"]
	rating_type_tab[i] = rating_type_res
end

local result = {} 
result["list"] = rating_type_tab
result["success"] = "true"
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))




