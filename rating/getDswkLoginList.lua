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

local personName = tostring(args["personName"])
local personName_str = "";
if personName == "nil" or personName == "" then

else
	personName_str = " and tdl.person_name like '%"..personName.."%'"
end

local tel = tostring(args["tel"])
local tel_str = "";
if tel == "nil" or tel == "" then

else
	tel_str = " and tdl.tel = '"..tel.."'"
end




local countsql = "select count(*) as count from (select tdl.person_id,tdl.person_name,tdl.tel,tdo.org_name from t_dswk_login tdl,t_dswk_organization tdo where tdo.org_id=tdl.org_id and  tdl.identity_id=1 "..personName_str..tel_str.." UNION ALL select tdl.person_id,tdl.person_name,tdl.tel,tdo.org_name from t_dswk_login tdl,t_base_organization tdo where tdo.org_id=tdl.org_id and  tdl.identity_id=1 "..personName_str..tel_str..") t"
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
 
local querysql = "select tdl.person_id,tdl.person_name,tdl.tel,tdo.org_name from t_dswk_login tdl,t_dswk_organization tdo where tdo.org_id=tdl.org_id and  tdl.identity_id=1 "..personName_str..tel_str.." UNION ALL select tdl.person_id,tdl.person_name,tdl.tel,tdo.org_name from t_dswk_login tdl,t_base_organization tdo where tdo.org_id=tdl.org_id and  tdl.identity_id=1 "..personName_str..tel_str.." limit "..offset..","..limit.."; "
local querysql_res,err,errno,sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
end
local returnjsonlist = {}
for i=1,#querysql_res do
  local resList = {}
    resList.person_id = querysql_res[i]["person_id"]
	resList.person_name = querysql_res[i]["person_name"]
	resList.tel = querysql_res[i]["tel"]
	resList.org_name = querysql_res[i]["org_name"]
    returnjsonlist[i] = resList
end

local returnjson = {}
returnjson["success"] = true
returnjson["list"] = returnjsonlist
returnjson["totalRow"] = totalRow
returnjson["totalPage"] = totalPage
returnjson["pageNumber"] = pageNumber
returnjson["pageSize"] = pageSize
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))







