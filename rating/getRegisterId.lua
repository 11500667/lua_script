local args = getParams();
local DBUtil = require "common.DBUtil"; 

local personId = args["person_id"];

if personId == nil or personId == "" then
	ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}");
	return;
end

	local querySql = " select person_id,person_name,login_name,login_password,identity_id,b_use,sex,tel,mail,qq_num,poscode,addr,org_id,stage,subject,nation,age,identity_num from t_dswk_login ";
	local whereSql = " where  person_id='"..personId.."'";
	querySql = querySql .. whereSql;
	ngx.log(ngx.ERR, "===> 根据菜单编码 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end	
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	ngx.print(encodeJson(resultDate));
