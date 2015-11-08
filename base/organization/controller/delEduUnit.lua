#删除教育单位 by huyue 2015-07-03

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

--orgId
local orgIdStr = ""
local orgId = ""
if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return
else
  orgId = args["org_id"]
  orgIdStr = "and ORG_ID="..orgId
end

--查询子节点
function getOrgTreeByOrgId(orgId)
  local orgTree=""
  local sql = "select org_id from t_base_organization where org_code like '%"..orgId.."%'";
  local res = mysql_db:query(sql);
  local org_tab = {}
  for i=1,#res do
    orgTree = orgTree..res[i]["org_id"]..","
  end
  return orgTree.sub(orgTree,1,string.len(orgTree)-1)
end

--判断部门是是否存在person
function isPersonExist(orgId)
  local countsql_person = "SELECT count(1) as count FROM T_BASE_PERSON WHERE 1=1 and BUREAU_ID in ("..orgId..") and IDENTITY_ID = 5 "
  local res_countsql_person,err,errno,sqlstate = mysql_db:query(countsql_person)
  ngx.log(ngx.ERR,countsql_person)
  if not res_countsql_person then
    ngx.log(ngx.ERR,"err: ".. err);
    return
  end
  local num_person = res_countsql_person[1]["count"]
  if tonumber(num_person) ~= 0 then
    return true
  else
    return false
  end
end


function delOrganization(orgId)
  local delsql = "delete from T_BASE_ORGANIZATION where org_id in ("..orgId..")"
  local delsql_res,err,errno,sqlstate = mysql_db:query(delsql)
  ngx.log(ngx.ERR,delsql)
  if not delsql_res then
    ngx.log(ngx.ERR,"err: ".. err);
    return
  end

end

function getOrgInfoCache(bureau_id)
  local querysql = "SELECT ORG_ID AS ID,ORG_NAME AS NAME,PARENT_ID AS PID FROM T_BASE_ORGANIZATION WHERE BUREAU_ID="..bureau_id.." ORDER BY SORT_ID DESC"
  local querysql_res,err,errno,sqlstate = mysql_db:query(querysql)
  ngx.log(ngx.ERR,querysql)
  if not querysql_res then
    ngx.log(ngx.ERR,"err: ".. err);
    return
  end
  return querysql_res
end

ngx.log(ngx.ERR, "**********删除教育单位开始**********");

local orgTree = getOrgTreeByOrgId(orgId);

local isExist = isPersonExist(orgTree)
if isExist == true then
  ngx.say("{\"success\":false,\"info\":\"该部门下存在人员信息，不能删除！\"}")
  return
end

delOrganization(orgTree)
local bureau_id = tostring(ngx.var.cookie_background_bureau_id)
local org_list = getOrgInfoCache(bureau_id)
if org_list ~= nil then
  local bureau_cache_tab = {}
  for i=1,#org_list do
    local bureau_table = {}
    bureau_table["id"] = org_list[i]["ID"];
    bureau_table["pId"] = org_list[i]["PID"];
    bureau_table["name"] = org_list[i]["NAME"];
    bureau_cache_tab[i]=bureau_table;
  end
  cache:set("bureau_"..bureau_id,cjson.encode(bureau_cache_tab));
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
local result = {}
result["success"] = true
result["info"] = "删除成功"
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


ngx.log(ngx.ERR, "**********删除教育单位结束**********")
