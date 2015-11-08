--新增组织 by huyue 2015-07-01

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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--parent_id
if args["parent_id"] == nil or args["parent_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"parent_id参数错误！\"}")
  return
end
local parent_id = args["parent_id"]

--org_name
if args["org_name"] == nil or args["org_name"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_name参数错误！\"}")
  return
end
local org_name = args["org_name"]

--查询父节点的信息
local query_org_sql = "select org_code,level,edu_type,district_id,city_id,province_id from t_base_organization where org_id="..parent_id;

ngx.log(ngx.ERR,"org_log------------>"..query_org_sql);

local query_org_res,err,errno,sqlstate = mysql_db:query(query_org_sql);

if not query_org_res then
	ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end
local district_id,city_id,province_id,edu_type,level,org_code;

if query_org_res[1] ~= nil then 

	district_id= query_org_res[1]["district_id"];
	city_id=query_org_res[1]["city_id"];
	province_id= query_org_res[1]["province_id"];
	edu_type=query_org_res[1]["edu_type"];
	level= query_org_res[1]["level"];
	org_code=query_org_res[1]["org_code"];
end

local sort_id=0;
if args["sort_id"] == nil or args["sort_id"] == "" then
  sort_id=0;
else
  sort_id=tonumber(args["sort_id"]);
end



local insert_org_sql="INSERT INTO T_BASE_ORGANIZATION (ORG_NAME,PARENT_ID,CREATE_TIME,BUREAU_ID,DISTRICT_ID,CITY_ID,PROVINCE_ID,LEVEL,ORG_TYPE,SORT_ID) VALUES('"..org_name.."',"..parent_id..",now(),"..parent_id..","..district_id..","..city_id..","..province_id..","..(level+1)..",3,"..sort_id..")";

ngx.log(ngx.ERR,"org_log---------->"..insert_org_sql);

local insert_org_res = mysql_db:query(insert_org_sql);

local org_id = insert_org_res.insert_id;

local new_org_code = org_code..org_id.."_";

local update_org_sql = "update t_base_organization set org_code = '"..new_org_code.."' where org_id="..org_id;

local update_org_res=mysql_db:query(update_org_sql);

--维护缓存

--获取当前登录人的部门ID
local loginperson_bureau_id =tostring(ngx.var.cookie_background_bureau_id); 
local bureau_cache_sql="SELECT ORG_ID AS ID,ORG_NAME AS NAME,PARENT_ID AS PID FROM T_BASE_ORGANIZATION WHERE org_code like '%_"..loginperson_bureau_id.."_%'";

local bureau_cache_res = mysql_db:query(bureau_cache_sql);


local bureau_cache_tab = {}
for i=1,#bureau_cache_res do
	local bureau_table = {}
	bureau_table["id"] = bureau_cache_res[i]["ID"];
	bureau_table["pId"] = bureau_cache_res[i]["PID"];
	bureau_table["name"] = bureau_cache_res[i]["NAME"];
	bureau_cache_tab[i]=bureau_table;
end

cache:set("bureau_"..loginperson_bureau_id,cjson.encode(bureau_cache_tab));

--维护缓存结束


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

local result = {} 
result.org_id = org_id;
result.org_name = org_name;
result.parent_id = tonumber(parent_id);
result.sort_id = sort_id;
result.open = true;
result.success = true;
result.info = "新增组织成功！";
ngx.print(cjson.encode(result));






