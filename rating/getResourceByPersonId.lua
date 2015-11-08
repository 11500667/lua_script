local args = getParams();
local _DBUtil = require "common.DBUtil";
-------------------------------前台输入--------------------------------------
--微课id
local personId = args["person_id"];
-------------------------------验证前台必须输入------------------------------
if personId == nil or personId == "" then
	ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}");
	return;
end
-----------------------------------------------------------------------------
local sql = "select wkds_id_int from  t_wkds_info where id =(select resource_info_id from t_rating_resource where person_id='"..personId.."')"
ngx.log(ngx.ERR,sql);
local querysql_res = _DBUtil:querySingleSql(sql);
local result = {};



if querysql_res[1] == nil then
result["success"] = false
result["info"] = "查询失败，未上传微课"
else
result["wkds_id_int"] = querysql_res[1]["wkds_id_int"];
result["success"] = true
result["info"] = "查询成功"
end


ngx.print(encodeJson(result))