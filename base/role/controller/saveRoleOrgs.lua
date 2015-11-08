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
--如果新增加的时候，组织ID不为空，如果之前有空 要把之前数据库里面组织ID为空的删除
local query_role_org_count_sql = "select count(1) as COUNT from t_sys_person_role where person_id = "..person_id.." and role_id="..role_id.." and identity_id="..identity_id.." and org_id is null";
	ngx.log(ngx.ERR,"hy_log--------->"..query_role_org_count_sql);
	local res_count = _DBUtil:querySingleSql(query_role_org_count_sql);
	local count = tonumber(res_count[1]["COUNT"])
	if count==1 then 
		--新增的时候如果有空，则把空的删除
	local del_role_org_sql="delete from t_sys_person_role where person_id = "..person_id.." and role_id="..role_id.." and org_id is null";
	local del_res = _DBUtil:querySingleSql(del_role_org_sql);

	end
 
end
local org_ids = args["org_ids"];


local org_id_tab= Split(org_ids,",");


for i=1,#org_id_tab do
	local query_sql = "select count(1) as COUNT from t_sys_person_role where person_id = "..person_id.." and role_id="..role_id.." and org_id= "..org_id_tab[i].." and identity_id="..identity_id;
	ngx.log(ngx.ERR,"查询角色组织-->"..query_sql);
	local query_count_res= _DBUtil:querySingleSql(query_sql);
	local count1 = tonumber(query_count_res[1]["COUNT"])
	if count1==0 then 
		--如果原来没有新增，原来有不做处理
		local insert_role_org_sql =  "insert into t_sys_person_role set role_id="..role_id..",person_id="..person_id..",identity_id="..identity_id..",org_id="..org_id_tab[i];
		ngx.log(ngx.ERR,"插入角色组织-->"..insert_role_org_sql);
		local res = _DBUtil:querySingleSql(insert_role_org_sql);
	else
	
	end
end

local result = {} 

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
