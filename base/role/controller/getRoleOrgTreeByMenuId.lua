--根据菜单ID获取角色组织  by huyue 2015-08-18
--1.获得参数方法
local args = getParams();
--引用模块
local cjson = require "cjson"

local _CacheUtil = require "common.CacheUtil";

local cache = _CacheUtil.getRedisConn();

local menu_id = args["menu_id"];
if menu_id == nil or menu_id == "" then
	ngx.say("{\"success\":false,\"info\":\"menu_id参数错误！\"}");
	return;
else
  menu_id = args["menu_id"];
end

local roleService = require "base.role.services.RoleService";

local user = tostring(ngx.var.cookie_background_user);

local user_cache =_CacheUtil:hmget("login_"..user,"person_id","identity_id");
local person_id = user_cache["person_id"];

local identity_id = user_cache["identity_id"];

local role_list = cache:lrange("role_"..person_id.."_"..identity_id, 0, -1);

local role_ids_str="";
for i=1,#role_list do
	role_ids_str = role_ids_str..role_list[i]..","
end 
  
if role_ids_str ~= nil and role_ids_str ~="" then 

	role_ids_str = string.sub(role_ids_str,0,string.len(role_ids_str)-1);
	else
	ngx.say("{\"success\":false,\"info\":\"当前登录人没有角色！\"}");
	return;
	
end 

local roleService = require "base.role.services.RoleService";
  
local current_role_ids  = roleService: getCurrentRolesByMenuIdAndRoleIds(menu_id,role_ids_str);

local current_role_ids_str="";
for i=1,#current_role_ids do
	current_role_ids_str = current_role_ids_str..current_role_ids[i]["role_id"]..","
end 

if current_role_ids_str ~= nil and current_role_ids_str ~="" then 

	current_role_ids_str = string.sub(current_role_ids_str,0,string.len(current_role_ids_str)-1);
	else
	ngx.say("{\"success\":false,\"info\":\"当前菜单没有对应角色！\"}");
	return;
	
end 

local result = roleService: getRoleOrgTreeByRoleIdsAndPersonId(person_id,current_role_ids_str,identity_id);



_CacheUtil:keepConnAlive(cache)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))