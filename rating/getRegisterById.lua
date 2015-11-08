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


--大赛id
if args["rating_id"] == nil or args["rating_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
  return
end
local rating_id = args["rating_id"]

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


--一页显示多少
local b_use = tostring(args["b_use"])
if b_use == "nil" then
	b_use = 0
end

local countsql = "select  count(*) as count from  (select tbo.org_id,tbo.org_name,trr.person_id,trr.file_id,tdl.person_name,tdl.tel from t_rating_register trr,t_dswk_login tdl,t_base_organization tbo where tbo.org_id=trr.school_id and  trr.person_id=tdl.person_id and trr.b_use="..b_use.." and   trr.rating_id="..rating_id.." union ALL select tdo.org_id,tdo.org_name,trr.person_id,trr.file_id,tdl.person_name,tdl.tel from t_rating_register trr,t_dswk_login tdl,t_dswk_organization tdo where tdo.org_id=trr.school_id and  trr.person_id=tdl.person_id and trr.b_use="..b_use.." and  trr.rating_id="..rating_id..") a"
local countsql_res, err, errno, sqlstate = db:query(countsql)
if not countsql_res then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local count1 = countsql_res[1]["count"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = countsql_res[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


local sqlRating = "select tbo.org_id,tbo.org_name,trr.person_id,trr.file_id,tdl.person_name,tdl.tel from t_rating_register trr,t_dswk_login tdl,t_base_organization tbo where tbo.org_id=trr.school_id and  trr.person_id=tdl.person_id and trr.b_use="..b_use.." and trr.rating_id="..rating_id.." union ALL select tdo.org_id,tdo.org_name,trr.person_id,trr.file_id,tdl.person_name,tdl.tel from t_rating_register trr,t_dswk_login tdl,t_dswk_organization tdo where tdo.org_id=trr.school_id and  trr.person_id=tdl.person_id and  trr.b_use="..b_use.." and  trr.rating_id="..rating_id.." limit "..offset..","..limit.."; "
local ratingQuery, err, errno, sqlstate = db:query(sqlRating)
ngx.log(ngx.ERR,sqlRating)
if not ratingQuery then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local list = {}
ngx.log(ngx.ERR,"=========================="..count1)

for i=1,#ratingQuery do
	local returnjsonlist = {}
  --[[
  returnjsonlist.works_name = ratingQuery[i]["works_name"]
  returnjsonlist.works_content = ratingQuery[i]["works_content"]
  returnjsonlist.works_version = ratingQuery[i]["works_version"]
  returnjsonlist.instructor_name = ratingQuery[i]["instructor_name"]
  returnjsonlist.instructor_sex = ratingQuery[i]["instructor_sex"]
  returnjsonlist.instructor_nation = ratingQuery[i]["instructor_nation"]
  returnjsonlist.instructor_email = ratingQuery[i]["instructor_email"]
  returnjsonlist.instructor_company = ratingQuery[i]["instructor_company"]
  returnjsonlist.instructor_tel = ratingQuery[i]["instructor_tel"]
  ]]
  returnjsonlist.org_name = ratingQuery[i]["org_name"]
  returnjsonlist.org_id = ratingQuery[i]["org_id"]
  returnjsonlist.person_name = ratingQuery[i]["person_name"]
  returnjsonlist.file_id = ratingQuery[i]["file_id"]
  returnjsonlist.tel = ratingQuery[i]["tel"]
  returnjsonlist.person_id = ratingQuery[i]["person_id"]
  list[i] = returnjsonlist
end

local returnjson = {}
returnjson.success = true
returnjson["list"] = list
returnjson["totalRow"] = totalRow
returnjson["totalPage"] = totalPage
returnjson["pageNumber"] = pageNumber
returnjson["pageSize"] = pageSize

db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))