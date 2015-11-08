--保存角色用户 by huyue 2015-08-03

--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
-- 获取数据库连接
local _DBUtil = require "common.DBUtil";

local _CacheUtil = require "common.CacheUtil";

local cache = _CacheUtil.getRedisConn();

if args["role_id"] == nil or args["role_id"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"role_id参数错误！\"}");
  return;
end
local role_id = args["role_id"];

local person_ids = tostring(args["person_ids"]); 
if args["person_ids"] == nil or args["person_ids"] == "" then
	person_ids="";
end

local person_id_tab= Split(person_ids,",");

for i=1,#person_id_tab do
	local query_identity_sql = "select identity_id from t_base_person where person_id="..person_id_tab[i];
	ngx.log(ngx.ERR,"hy_log-->根据用户查询身份"..query_identity_sql);
	local query_identity_res= _DBUtil:querySingleSql(query_identity_sql);

	local identity_id=tonumber(query_identity_res[1]["identity_id"]);
	local query_role_user_count_sql = "select count(1) as COUNT from t_sys_person_role where person_id="..tonumber(person_id_tab[i]).." and role_id="..role_id;
	ngx.log(ngx.ERR,"hy_log--------->"..query_role_user_count_sql);
	local res_count = _DBUtil:querySingleSql(query_role_user_count_sql);
	local count = tonumber(res_count[1]["COUNT"])
	if count==0 then 
	--查询组织
	local query_org_sql;
	if identity_id == 6 then 
	
		query_org_sql = "select c.org_id  from t_base_student s join t_base_class c on s.class_id = c.class_id where s.student_id ="..person_id_tab[i];
	
	else 
	
		query_org_sql ="select org_id from t_base_person where person_id ="..person_id_tab[i].." and identity_id ="..identity_id;
	end
	
	local query_org_res=_DBUtil:querySingleSql(query_org_sql);
	
	local org_id;
	
	local insert_role_user_sql =  "insert into t_sys_person_role set role_id="..role_id..",person_id="..person_id_tab[i]..",identity_id="..identity_id;
	if query_org_res==nil or query_org_res[1] == nil or query_org_res[1]["org_id"] == ngx.null then
	
	else
		org_id = query_org_res[1]["org_id"];
		insert_role_user_sql = insert_role_user_sql..",org_id ="..org_id;
	end
	
	
	ngx.log(ngx.ERR,"插入角色用户-->"..insert_role_user_sql);
	local res = _DBUtil:querySingleSql(insert_role_user_sql);
	

	--维护缓存
	ngx.log(ngx.ERR,"cache key-->".."role_"..person_id_tab[i].."_"..identity_id);
	cache:rpush("role_"..person_id_tab[i].."_"..identity_id, tostring(role_id));
	end
end

_CacheUtil:keepConnAlive(cache)
local result = {} 

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
