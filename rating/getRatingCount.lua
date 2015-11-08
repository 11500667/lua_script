local args = getParams();
local DBUtil = require "common.DBUtil"; 
-------------------------------前台输入--------------------------------------
--大赛id
local rating_id = args["rating_id"];
--学段
local stage_id = args["stage_id"];

-------------------------------验证前台必须输入------------------------------
if rating_id == nil or rating_id == "" then
	ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}");
	return;
end
if stage_id == nil or stage_id == "" then
	ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}");
	return;
end

-----------------------------------------------------------------------------

-------------------------------后台获取--------------------------------------
local subjectSql = "select subject_id from t_dm_subject where stage_id='"..stage_id.."'";
local subjectSql_res = DBUtil: querySingleSql(subjectSql);
if not subjectSql_res then
	return false;
end
local returnjsonlist = {};
for i=1,#subjectSql_res do
	local countList = {};
	local subject_id = subjectSql_res[i]["subject_id"];
	local querySql = " select count(*) as count,tds.subject_name from t_rating_resource trr,t_dm_subject tds where trr.rating_id='"..rating_id.."' and trr.stage_id='"..stage_id.."' and trr.subject_id='"..subject_id.."' and trr.subject_id=tds.subject_id";
	ngx.log(ngx.ERR,querySql)
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end	
	countList.count = querysql_res[1]["count"];
	countList.subject_name = querysql_res[1]["subject_name"];
	returnjsonlist[i] = countList;
end

local resultDate = {};
resultDate.list = returnjsonlist
resultDate.success = true;
ngx.print(encodeJson(resultDate));

