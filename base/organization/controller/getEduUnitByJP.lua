--根据简拼获取教育单位详情 by huyue 2015-08-18 
--1.获得参数方法
local args = getParams();
-- 获取数据库连接
local _DBUtil = require "common.DBUtil";

--引用模块
local cjson = require "cjson"


local query_condition = ""
local jp = ""
if args["jp"] == nil or args["jp"] == "" then
  ngx.say("{\"success\":false,\"info\":\"jp参数错误！\"}")
  return
else
  jp = args["jp"]
  query_condition = " and JP='"..jp.."'"
end


ngx.log(ngx.ERR, "**********根据组织ID获取教育单位开始**********"); 
local querysql = "SELECT T1.ORG_ID,T1.JP,T1.ORG_NAME,T2.TYPE_NAME,T1.DESCRIPTION,T1.EDU_TYPE,T1.SCHOOL_TYPE,T1.ADDRESS,T1.CREATE_TIME,T1.BUSINESS_SYSTEM_SOURCE,T1.AREA_ID,T1.ORG_TYPE,T1.MAIN_SCHOOL_ID,T1.PARENT_ID,T1.SORT_ID  FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE 1=1 "..query_condition
local querysql_res =  _DBUtil:querySingleSql(querysql)
ngx.log(ngx.ERR,querysql)


if querysql_res==nil or querysql_res[1]==nil  then
	
	ngx.say("{\"success\":false,\"info\":\"jp不存在！\"}");
	return;
	
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


local JP = querysql_res[1]["JP"]
local DESCRIPTION = querysql_res[1]["DESCRIPTION"]
local BUSINESS_SYSTEM_SOURCE=querysql_res[1]["BUSINESS_SYSTEM_SOURCE"]
local MAIN_SCHOOL_NAME;
local returnjson = {}
if MAIN_SCHOOL_ID == ngx.null or tonumber(MAIN_SCHOOL_ID) == tonumber(orgId) then

else
  local school_id_str = " and ORG_ID="..MAIN_SCHOOL_ID
  local quertsql_1 = "select ORG_NAME FROM T_BASE_ORGANIZATION  WHERE 1=1 "..school_id_str
  local querysql_res1 = _DBUtil:querySingleSql(quertsql_1)
  ngx.log(ngx.ERR,quertsql_1)

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

returnjson["JP"] = JP
returnjson["BUSINESS_SYSTEM_SOURCE"] = BUSINESS_SYSTEM_SOURCE
returnjson["DESCRIPTION"] = DESCRIPTION
ngx.log(ngx.ERR,cjson.encode(returnjson))



cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(returnjson))
