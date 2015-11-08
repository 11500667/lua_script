--修改角色  by huyue 2015-08-04
local request_method = ngx.var.request_method
local args = getParams();

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local _DBUtil = require "common.DBUtil";

--角色ID
if args["role_id"] == nil or args["role_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"role_id参数错误！\"}")
  return
end
local role_id = args["role_id"]

--角色名称
if args["role_name"] == nil or args["role_name"] == "" then
  ngx.say("{\"success\":false,\"info\":\"role_name参数错误！\"}")
  return
end
local role_name = args["role_name"]

--角色编码
local role_code = args["role_code"]
if args["role_code"] == nil or args["role_code"] == "" then
  role_code="";
  
else
--如果填写了角色编码要校验
local check_sql="select count(1) as COUNT from t_sys_role where role_code ='"..role_code.."' and role_id<>"..role_id;
local check_res=_DBUtil:querySingleSql(check_sql);

if check_res and check_res[1] then 
	if tonumber(check_res[1]["COUNT"]) >0 then
		  ngx.say("{\"success\":false,\"info\":\""..role_code.."已存在,不能重复添加！\"}");
		  return;
	end
end
end

--业务系统来源
if args["business_system"] == nil or args["business_system"] == "" then
    ngx.say("{\"success\":false,\"info\":\"参数business_system不能为空！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数business_system不能为空！");
    return
end
local business_system  = args["business_system"];

local update_role_sql="update t_sys_role set role_name='"..role_name.."',role_code='"..role_code.."',business_system_source='"..business_system.."' where role_id="..role_id..";";

ngx.log(ngx.ERR,"role_log---------->"..update_role_sql);

local insert_role_res = _DBUtil:querySingleSql(update_role_sql);

cjson.encode_empty_table_as_object(false);
local result = {} 

result.success = true;
result.info = "修改角色成功！";

ngx.print(cjson.encode(result));






