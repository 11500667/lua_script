--删除角色组织 by huyue 2015-08-06
--保存角色所在组织 by huyue 2015-08-06 
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
-- 获取数据库连接
local _DBUtil = require "common.DBUtil";


if args["role_id"] == nil or args["role_id"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"role_id参数错误！\"}");
  return;
end
local role_id = args["role_id"];

local person_id = tostring(args["person_id"]); 
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}");
  return;
end
local person_id = args["person_id"];


--根据person_id查询身份
local query_identity_sql = "select identity_id from t_base_person where person_id="..person_id;
ngx.log(ngx.ERR,"hy_log-->根据用户查询身份"..query_identity_sql);
local query_identity_res= _DBUtil:querySingleSql(query_identity_sql);

local identity_id=tonumber(query_identity_res[1]["identity_id"]);

local org_ids = tostring(args["org_ids"]); 
if args["person_id"] == nil or args["person_id"] == "" then
  org_ids="";
else

 
end
local org_ids = args["org_ids"];


local org_id_tab= Split(org_ids,",");


for i=1,#org_id_tab do

local del_sql="delete from t_sys_person_role where person_id="..person_id.." and role_id="..role_id.." and org_id="..org_id_tab[i].." and identity_id="..identity_id;
ngx.log(ngx.ERR,"删除角色所在组织-- >"..del_sql);

local del_res= _DBUtil:querySingleSql(del_sql);
	
end

--删除之后如果一个也没有 需要插入一个组织ID为空的
local query_count_sql = "select count(1) as COUNT from t_sys_person_role where person_id = "..person_id.." and role_id="..role_id.." and identity_id="..identity_id;
ngx.log(ngx.ERR,"hy_log--------->"..query_count_sql);
local res_count = _DBUtil:querySingleSql(query_count_sql);
local count = tonumber(res_count[1]["COUNT"])
if count==0 then 
	local insert_sql="insert into t_sys_person_role set role_id="..role_id..",person_id="..person_id..",identity_id="..identity_id;
	local insert_res = _DBUtil:querySingleSql(insert_sql);
end

local result = {} 

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
