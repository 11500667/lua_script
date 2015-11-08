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
local check_sql="select count(1) as COUNT from t_sys_role where role_code ='"..role_code.."'";
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


local query_identity_sql= "SELECT IDENTITY_TYPE FROM T_SYS_IDENTITY WHERE IDENTITY_ID = "..identity_id;

local query_identity_res=_DBUtil:querySingleSql(query_identity_sql);

local role_type = "";
if query_identity_res and query_identity_res[1] then 
	role_type=query_identity_res[1]["IDENTITY_TYPE"];

end


local insert_role_sql="INSERT INTO T_SYS_ROLE (ROLE_NAME, ROLE_CODE,ROLE_TYPE, IDENTITY_ID,BUSINESS_SYSTEM_SOURCE,B_USE) VALUES ('"..role_name.."','"..role_code.."',"..role_type..","..identity_id..",'"..business_system.."',1)";

ngx.log(ngx.ERR,"role_log---------->"..insert_role_sql);

local insert_role_res = _DBUtil:querySingleSql(insert_role_sql);

local role_id = insert_role_res.insert_id;



cjson.encode_empty_table_as_object(false);
local result = {} 

result.success = true;
result.info = "新增角色成功！";
ngx.print(cjson.encode(result));






