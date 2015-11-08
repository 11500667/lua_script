--根据主校ID 获取分校信息 包含主校自己  by huyue 2015-07-17
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

local org_id = ""
if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return
else
  org_id = args["org_id"]

end


ngx.log(ngx.ERR, "**********根据组织ID获取分校**********"); 
local querysql = "SELECT T1.ORG_ID,T1.JP,T1.ORG_NAME,T2.TYPE_NAME,T1.EDU_TYPE,T1.SCHOOL_TYPE,T1.ADDRESS,T1.CREATE_TIME,T1.AREA_ID,T1.ORG_TYPE,T1.MAIN_SCHOOL_ID,T1.PARENT_ID,T1.SORT_ID,T1.DISTRICT_ID,T1.CITY_ID,T1.PROVINCE_ID FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE 1=1 AND MAIN_SCHOOL_ID="..org_id.." OR ORG_ID="..org_id;
local res, err, errno, sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not res then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

if res[1] == nil then
	ngx.say("{\"success\":false,\"info\":\"org_id不存在！\"}")
  return
end

local org_tab = {}
for i=1,#res do
local org_res = {}

	local org_res = {}
	org_res["ORG_ID"] = res[i]["ORG_ID"]
	org_res["ORG_NAME"] = res[i]["ORG_NAME"]
	org_res["TYPE_NAME"] = res[i]["TYPE_NAME"]
	org_res["ADDRESS"] = res[i]["ADDRESS"]
	org_res["CREATE_TIME"] = res[i]["CREATE_TIME"]
	org_res["AREA_ID"] = res[i]["AREA_ID"]
	org_res["ORG_TYPE"] = res[i]["ORG_TYPE"]
	org_res["JP"] = res[i]["JP"]
	
	org_res["EDU_TYPE"] = res[i]["EDU_TYPE"]
	org_res["MAIN_SCHOOL_ID"] = res[i]["MAIN_SCHOOL_ID"]
	org_res["SORT_ID"] = res[i]["SORT_ID"]
	org_res["DISTRICT_ID"] = res[i]["DISTRICT_ID"]
	org_res["CITY_ID"] = res[i]["CITY_ID"]
	org_res["PROVINCE_ID"] = res[i]["PROVINCE_ID"]
	org_tab[i] = org_res
end

local result = {} 
result["table_List"] = org_tab

result["success"] = true
ngx.log(ngx.ERR,cjson.encode(result))

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
