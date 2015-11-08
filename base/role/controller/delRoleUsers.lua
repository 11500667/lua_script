--删除角色用户 by huyue 2015-08-05
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
local role_id = tonumber(args["role_id"]);



if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}");
  return;
end
local person_id = args["person_id"];
local query_identity_sql = "select identity_id from t_base_person where person_id="..person_id;
ngx.log(ngx.ERR,"hy_log-->根据用户查询身份"..query_identity_sql);
local query_identity_res= _DBUtil:querySingleSql(query_identity_sql);

local identity_id=tonumber(query_identity_res[1]["identity_id"]);

local del_role_user="delete from t_sys_person_role where person_id ="..person_id.." and role_id ="..role_id;

local del_res= _DBUtil:querySingleSql(del_role_user);


local role_list = cache:lrange("role_"..person_id.."_"..identity_id, 0, -1);


cache:del("role_"..person_id.."_"..identity_id);


for i=1,#role_list do

	if role_id ~= tonumber(role_list[i]) then
		ngx.log(ngx.ERR,role_id.."---------------------");
		cache:rpush("role_"..person_id .."_"..identity_id,tostring(role_list[i]));
	end
end

_CacheUtil:keepConnAlive(cache)
local result = {} 

result["success"] = true
result["info"] = "删除成功！";
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
