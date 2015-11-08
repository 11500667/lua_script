local args = getParams();
local _DBUtil = require "common.DBUtil";
-------------------------------前台输入--------------------------------------
--微课id
local resourceId = args["resource_id"];
--微课名称
local resourceName = args["resource_name"];
-------------------------------验证前台必须输入------------------------------
if resourceId == nil or resourceId == "" then
	ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}");
	return;
end
if resourceName == nil or resourceName == "" then
	ngx.say("{\"success\":false,\"info\":\"resource_name参数错误！\"}");
	return;
end
-----------------------------------------------------------------------------
local sql = "update t_rating_register set works_name='"..resourceName.."' where person_id=(select person_id from t_rating_resource where resource_info_id='"..resourceId.."')";
ngx.log(ngx.ERR,sql);
local querysql_res = _DBUtil:querySingleSql(sql);
local result = {};
result["success"] = true
ngx.print(encodeJson(result))
