#ngx.header.content_type = "text/plain;charset=utf-8"
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

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
  ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
  return
end

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

if not ok then
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
  ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
  return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
  return
end
local pageSize = args["pageSize"]

local province_str 
if args["province_id"] == nil or args["province_id"] == "" then
	province_str = ""
else
	province_str = " and province_id = "..args["province_id"].." "
end

local city_str 
if args["city_id"] == nil or args["city_id"] == "" then
	city_str = ""
else
	city_str = " and city_id = "..args["city_id"].." "
end

local district_str 
if args["district_id"] == nil or args["district_id"] == "" then
	district_str = ""
else
	district_str = " and district_id = "..args["district_id"].." "
end

ngx.log(ngx.ERR, "**********东师理想微课大赛*****获取学校开始**********");	


local countsql = "select sum(tmpcount) as count  from ( select count(*) as tmpcount from t_base_organization where ORG_TYPE = 2 and B_USE = 1 "..province_str..city_str..district_str.." union all  select count(*) as tmpcount from t_dswk_organization where b_use=1 "..province_str..city_str..district_str..") a"
local countsql_res,err,errno,sqlstate = db:query(countsql)
ngx.log(ngx.ERR,countsql)
if not countsql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = countsql_res[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)



            


local querysql = "(select org_id,org_name from t_base_organization where ORG_TYPE = 2 and B_USE = 1 "..province_str..city_str..district_str..") union all (select org_id,org_name from t_dswk_organization where B_USE = 1"..province_str..city_str..district_str..")  LIMIT "..offset..","..limit.."; "
local querysql_res,err,errno,sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
end

local returnjsonlist = {}
for i=1,#querysql_res do
	local resList = {}
    resList.org_id = querysql_res[i]["org_id"]
    resList.org_name = querysql_res[i]["org_name"]
    returnjsonlist[i] = resList

end

local returnjson = {}
returnjson["success"] = true
returnjson["list"] = returnjsonlist


cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****获取学校结束**********");	























