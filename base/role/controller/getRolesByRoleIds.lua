--根据角色ID 获取角色详情 by huyue 2015-09-10
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"


local role_ids=args["role_ids"];

if role_ids == nil or role_ids == "" then
	ngx.say("{\"success\":false,\"info\":\"role_ids参数错误！\"}");
	return;
else
  role_ids = args["role_ids"];
end

local roleService = require "base.role.services.RoleService";
local result  = roleService:getRolesByRoleIds(role_ids);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))