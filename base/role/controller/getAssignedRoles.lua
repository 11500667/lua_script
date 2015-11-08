--获取已经分配的角色 by huyue 2015-08-14
--增加角色 by huyue 2015-08-03
local request_method = ngx.var.request_method
local args = getParams();

--引用模块
local cjson = require "cjson"


local _DBUtil = require "common.DBUtil";

--身份ID
if args["identity_id"] == nil or args["identity_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
  return
end
local identity_id = args["identity_id"]

if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]


local query_role_sql="select ROLE_ID,ROLE_NAME,0 as is_check from t_sys_role where identity_id = "..identity_id;

local query_res=_DBUtil:querySingleSql(query_role_sql);

local query_check_role_sql="select distinct ROLE_ID from t_sys_person_role where person_id ="..person_id.."  and identity_id ="..identity_id;

local query_check_role_res = _DBUtil:querySingleSql(query_check_role_sql);
cjson.encode_empty_table_as_object(false);
local result = {} 
if query_res then
	for i=1,#query_res do
		if  query_check_role_res then 
			for j=1,#query_check_role_res do
				if tonumber(query_res[i]["ROLE_ID"])==tonumber(query_check_role_res[j]["ROLE_ID"]) then
					query_res[i]["is_check"]=1		
				end
			end
		end
	end
result.table_List=query_res;
result.success = true;
	
else 

result.info="该身份下没有角色";
result.success = false;
	
end

ngx.print(cjson.encode(result));
