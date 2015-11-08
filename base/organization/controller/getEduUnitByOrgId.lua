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
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end


--orgId
local orgIdStr = ""
local org_id = ""
if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return
else
  org_id = args["org_id"]
  orgIdStr = "and ORG_ID="..org_id
end


ngx.log(ngx.ERR, "**********根据组织ID获取教育单位开始**********"); 
local querysql = "SELECT T1.ORG_ID,T1.JP,T1.ORG_NAME,T2.TYPE_NAME,T1.DESCRIPTION,T1.EDU_TYPE,T1.SCHOOL_TYPE,T1.ADDRESS,T1.CREATE_TIME,T1.BUSINESS_SYSTEM_SOURCE,T1.AREA_ID,T1.ORG_TYPE,T1.MAIN_SCHOOL_ID,T1.PARENT_ID,T1.SORT_ID,T1.DISTRICT_ID,T1.CITY_ID,T1.PROVINCE_ID FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE 1=1 "..orgIdStr
local querysql_res, err, errno, sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not querysql_res then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

if querysql_res[1] == nil then
	ngx.say("{\"success\":false,\"info\":\"org_id不存在！\"}")
  return
end

local ORG_ID = querysql_res[1]["ORG_ID"]
local ORG_NAME = querysql_res[1]["ORG_NAME"]
local TYPE_NAME = querysql_res[1]["TYPE_NAME"]
local ADDRESS = querysql_res[1]["ADDRESS"]
local CREATE_TIME = querysql_res[1]["CREATE_TIME"]
local AREA_ID = querysql_res[1]["AREA_ID"]
local ORG_TYPE = querysql_res[1]["ORG_TYPE"]
local MAIN_SCHOOL_ID = querysql_res[1]["MAIN_SCHOOL_ID"]
local PARENT_ID = querysql_res[1]["PARENT_ID"]
local SORT_ID = querysql_res[1]["SORT_ID"]
local EDU_TYPE=querysql_res[1]["EDU_TYPE"]
local SCHOOL_TYPE = querysql_res[1]["SCHOOL_TYPE"]
local DISTRICT_ID = querysql_res[1]["DISTRICT_ID"]
local CITY_ID = querysql_res[1]["CITY_ID"]
local PROVINCE_ID = querysql_res[1]["PROVINCE_ID"]
local JP = querysql_res[1]["JP"]
local DESCRIPTION = querysql_res[1]["DESCRIPTION"]
local BUSINESS_SYSTEM_SOURCE=querysql_res[1]["BUSINESS_SYSTEM_SOURCE"]
local MAIN_SCHOOL_NAME;
local returnjson = {}
if MAIN_SCHOOL_ID == ngx.null or tonumber(MAIN_SCHOOL_ID) == tonumber(orgId) then

else
  local school_id_str = " and ORG_ID="..MAIN_SCHOOL_ID
  local quertsql_1 = "select ORG_NAME FROM T_BASE_ORGANIZATION  WHERE 1=1 "..school_id_str
  local querysql_res1, err, errno, sqlstate = db:query(quertsql_1)
  ngx.log(ngx.ERR,quertsql_1)
  if not querysql_res1 then
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
  if querysql_res1[1] == nil then
	ngx.say("{\"success\":false,\"info\":\"获取ORG_NAME失败！\"}")
	return
  else
	if querysql_res1[1]["ORG_NAME"] ~= ngx.null then
	MAIN_SCHOOL_NAME = querysql_res1[1]["ORG_NAME"];
	returnjson["MAIN_SCHOOL_NAME"] = MAIN_SCHOOL_NAME;
	end
  end
end


returnjson["success"] = true
returnjson["info"] = "获取成功"
returnjson["ORG_ID"] = ORG_ID
returnjson["ORG_NAME"] = ORG_NAME
returnjson["TYPE_NAME"] = TYPE_NAME
returnjson["ADDRESS"] = ADDRESS
returnjson["CREATE_TIME"] = CREATE_TIME
returnjson["AREA_ID"] = AREA_ID
returnjson["ORG_TYPE"] = ORG_TYPE
returnjson["MAIN_SCHOOL_ID"] = MAIN_SCHOOL_ID
returnjson["PARENT_ID"] = PARENT_ID
returnjson["SORT_ID"] = SORT_ID
returnjson["EDU_TYPE"] = EDU_TYPE
returnjson["SCHOOL_TYPE"] = SCHOOL_TYPE
returnjson["DISTRICT_ID"] = DISTRICT_ID
returnjson["CITY_ID"] = CITY_ID
returnjson["PROVINCE_ID"] = PROVINCE_ID
returnjson["JP"] = JP
returnjson["BUSINESS_SYSTEM_SOURCE"] = BUSINESS_SYSTEM_SOURCE
returnjson["DESCRIPTION"] = DESCRIPTION
ngx.log(ngx.ERR,cjson.encode(returnjson))

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(returnjson))
