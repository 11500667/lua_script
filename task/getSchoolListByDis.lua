local args = getParams();
local DBUtil = require "common.DBUtil";
-------------------------------前台输入--------------------------------------
--菜单编号
local disId = args["dis_id"];
--页码
local pageNumber = args["pageNumber"]
--页显示数量
local pageSize = args["pageSize"]
-------------------------------验证前台必须输入------------------------------
if disId == nil or disId == "" then
  ngx.say("{\"success\":false,\"info\":\"dis_id参数错误！\"}");
  return;
end

-----------------------------------------------------------------------------

-------------------------------后台获取--------------------------------------
local resultDate = {};
local querySql = "";
if tonumber(disId) > 100000 and tonumber(disId) < 200000 then
--省 
	resultDate.info="省";
elseif tonumber(disId) > 200000 and tonumber(disId) < 300000 then
--市
	resultDate.info="市";
	querySql= "select org_name,org_id from t_base_organization where city_id = "..disId.."  and B_USE=1 and ORG_TYPE in (1,2)";
else
--区
	resultDate.info="区";
	querySql= "select org_name,org_id from t_base_organization where district_id = "..disId.."  and B_USE=1 and ORG_TYPE in (1,2)";
end
ngx.log(ngx.ERR, "===> 根据主任务编号与子任务编号获取任务详细信息 ===> ", querySql);
local querysql_res = DBUtil: querySingleSql(querySql);
if not querysql_res then
  return false;
end
resultDate.list = querysql_res;
resultDate.success = true;
ngx.print(encodeJson(resultDate));