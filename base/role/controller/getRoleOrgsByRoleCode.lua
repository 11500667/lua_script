--根据角色编码和人员信息获取人员能够管理的组织 by huyue 2015-08-27
local args = getParams();
--引用模块
local cjson = require "cjson"


local person_id = args["person_id"];
if person_id == nil or person_id == "" then
	ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}");
	return;
else
  person_id = args["person_id"];
end

local identity_id = args["identity_id"];
if identity_id == nil or identity_id == "" then
	ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}");
	return;
else
  identity_id = args["identity_id"];
end


local roleService = require "base.role.services.RoleService";

local role_code = args["role_code"];
if role_code == nil or role_code == "" then
	ngx.say("{\"success\":false,\"info\":\"role_code参数错误！\"}");
	return;
else
  role_code = args["role_code"];
end

local result = roleService: getRoleOrgTreeByRoleCodeAndPersonId(person_id,role_code,identity_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))