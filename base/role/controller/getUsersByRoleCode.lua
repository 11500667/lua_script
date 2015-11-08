--根据角色编码获取用户 by huyue 2015-08-14
--1.获得参数方法
local args = getParams();
--引用模块
local cjson = require "cjson"

local role_code = args["role_code"];
if role_code == nil or role_code == "" then
	ngx.say("{\"success\":false,\"info\":\"role_code参数错误！\"}");
	return;
else
  role_code = args["role_code"];
end

local roleService = require "base.role.services.RoleService";

if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]
  
local result  = roleService: getUsersByRoleCode(role_code,pageSize,pageNumber);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))