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

local res_count = db:query("select count(*) as count from t_rating_experts where rating_id='"..rating_id.."'")



local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)



local querySql = "select id,stage_id,subject_id,login_id,login_pwd,login_pwd_rel from t_rating_experts where rating_id='"..rating_id.."' order by id DESC LIMIT "..offset..","..limit..";"
local ex, err, errno, sqlstate = db:query(querySql)
ngx.log(ngx.ERR,querySql)
if not ex then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


local returnjson = {}
returnjson.success = true

local personArray = {}
for i=1,#ex do
local tab = {}
tab.id=ex[i]["id"];


local stage_info
if ex[i]["stage_id"] == ngx.null or ex[i]["stage_id"] == 0  then
tab.stage_name=""
else
stage_info = db:query("SELECT stage_name FROM   t_dm_stage WHERE  STAGE_ID = "..tostring(ex[i]["stage_id"]).." ")
ngx.log(ngx.ERR,"SELECT stage_name FROM   t_dm_stage WHERE  STAGE_ID = "..tostring(ex[i]["stage_id"]).." ")
tab.stage_name = stage_info[1]["stage_name"]
end
tab.stage_id=ex[i]["stage_id"]


local subject_info
if ex[i]["subject_id"] == ngx.null or ex[i]["subject_id"] == 0  then
tab.subject_name =""
else
subject_info = db:query("SELECT subject_name FROM   t_dm_subject WHERE  SUBJECT_ID = "..ex[i]["subject_id"].." ")
tab.subject_name = subject_info[1]["subject_name"]
end
tab.subject_id=ex[i]["subject_id"]


tab.login_id=ex[i]["login_id"];
tab.login_pwd=ex[i]["login_pwd_rel"];
table.insert(personArray, tab);

end
returnjson.list = personArray
returnjson["totalRow"] = tonumber(totalRow)
returnjson["totalPage"] = tonumber(totalPage)
returnjson["pageNumber"] = tonumber(pageNumber)
returnjson["pageSize"] = tonumber(pageSize)
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))








