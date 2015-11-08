--新增行政区划 by huyue 2015-08-19
local args = getParams();

--引用模块
local cjson = require "cjson"

local _CacheUtil = require "common.CacheUtil";

local cache = _CacheUtil.getRedisConn();

--国标码
local area_code = args["area_code"];
if area_code == nil or area_code == "" then
	ngx.say("{\"success\":false,\"info\":\"area_code参数错误！\"}");
	return;
else
  area_code = args["area_code"];
end

--行政区划名称
local area_name = args["area_name"];
if area_name == nil or area_name == "" then
	ngx.say("{\"success\":false,\"info\":\"area_name参数错误！\"}");
	return;
else
  area_name = args["area_name"];
end


--父节点ID
local parent_id = args["parent_id"];
if parent_id == nil or parent_id == "" then
	ngx.say("{\"success\":false,\"info\":\"parent_id参数错误！\"}");
	return;
else
  parent_id = args["parent_id"];
end

local area_type = args["area_type"];
if area_type == nil or area_type == "" then
	ngx.say("{\"success\":false,\"info\":\"area_type参数错误！\"}");
	return;
else
  area_type = args["area_type"];
end

local user = tostring(ngx.var.cookie_background_user);
local user_cache =_CacheUtil:hmget("login_"..user,"person_id");
local created_by = user_cache["person_id"];

local areaService = require "base.area.services.AreaService";
  
local result  = areaService:addArea(area_name,parent_id,area_type,area_code,created_by);

_CacheUtil:keepConnAlive(cache)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))