--给用户分配角色 by huyue 2015-08-14
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
-- 获取数据库连接
local _DBUtil = require "common.DBUtil";

local _CacheUtil = require "common.CacheUtil";

local cache = _CacheUtil.getRedisConn();

if args["person_id"] == nil or args["person_id"] == "" then
	ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}");
	return;
end

local person_id = tostring(args["person_id"]); 
if args["identity_id"] == nil or args["identity_id"] == "" then
	ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}");
	return;
end
local identity_id = args["identity_id"]; 

local role_ids;
local addRoleId; 
if args["role_ids"] == nil or args["role_ids"] == "" then
--角色全部删除
	cache:del("role_"..person_id.."_"..identity_id);
	local delete_sql =  "delete from  t_sys_person_role where role_id="..delRoleId[i].." and person_id="..person_id.." and identity_id="..identity_id;
	ngx.log(ngx.ERR,"删除用户角色-->"..delete_sql);
	local del_res=_DBUtil:querySingleSql(delete_sql);
	ngx.say("{\"success\":\"true\"}");
	return;

else
	--维护缓存
	role_ids = args["role_ids"];
	addRoleId = Split(role_ids,",");
	cache:del("role_"..person_id.."_"..identity_id);
	for n=1,#addRoleId do
		cache:rpush("role_"..person_id.."_"..identity_id, addRoleId[n]);
	end 
	--cache:set("role_"..person_id.."_"..identity_id, Split(role_ids,","));
end



local query_old_sql="select distinct ROLE_ID from t_sys_person_role where person_id ="..person_id.." and identity_id ="..identity_id;
ngx.log(ngx.ERR,"hy_log-------->查询用户角色"..query_old_sql);

local query_old_res=_DBUtil:querySingleSql(query_old_sql);

local role_id_old_tab={};

for m=1,#query_old_res do 
	role_id_old_tab[m]=query_old_res[m]["ROLE_ID"];
end




local delRoleId=role_id_old_tab;
local role_id_new_tab= Split(role_ids,",");

local add_remove={};
for i, v in ipairs(addRoleId) do
  for j, value in ipairs(role_id_old_tab) do
	ngx.log(ngx.ERR,"v:"..v.."value:"..value);
      if tonumber(v)  == tonumber(value) then

      add_remove[tostring(v)]=true;
 
      end
  end

end


local i = 1
while i <= #addRoleId do
  if add_remove[tostring(addRoleId[i])] then

    table.remove(addRoleId, i)
  else
    i = i + 1
  end
end



local del_remove={};

for i, v in ipairs(delRoleId) do
  for j, value in ipairs(role_id_new_tab) do
      if tonumber(v)  == tonumber(value) then
      del_remove[tostring(v)]=true;
      end
  end

end

local j = 1
while j <= #delRoleId do
  if del_remove[tostring(delRoleId[j])] then

    table.remove(delRoleId, j)
  else
    j = j + 1
  end
end




for i=1,#addRoleId do	

	local insert_role_user_sql =  "insert into t_sys_person_role set role_id="..addRoleId[i]..",person_id="..person_id..",identity_id="..identity_id;
	ngx.log(ngx.ERR,"插入用户角色-->"..insert_role_user_sql);
	local res = _DBUtil:querySingleSql(insert_role_user_sql);
	
end

for i=1,#delRoleId do	

	local delete_role_user_sql =  "delete from  t_sys_person_role where role_id="..delRoleId[i].." and person_id="..person_id.." and identity_id="..identity_id;
	ngx.log(ngx.ERR,"插入用户角色-->"..delete_role_user_sql);
	local res = _DBUtil:querySingleSql(delete_role_user_sql);
	--cache:hdel("role_"..person_id.."_"..identity_id, tostring(delRoleId[i]));
end




_CacheUtil:keepConnAlive(cache)


local result = {} 

result["success"] = true
--result["addRoleId"]=addRoleId;
--result["delRoleId"]=delRoleId;

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
