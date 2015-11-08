local args = getParams();
local DBUtil = require "common.DBUtil"; 
-------------------------------前台输入--------------------------------------
--大赛id
local rating_id = args["rating_id"];
-------------------------------验证前台必须输入------------------------------
if rating_id == nil or rating_id == "" then
	ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}");
	return;
end
-----------------------------------------------------------------------------

-------------------------------后台获取--------------------------------------
--参赛人数
local person_count_sql = " select count(*) as person_count from t_rating_register where rating_id='"..rating_id.."' ";
--参赛作品
local resource_count_sql = " select count(*) as resource_count from t_rating_resource where rating_id='"..rating_id.."' ";
--入围作品
local lis_count_sql = " select count(*) as lis_count from t_rating_resource where rating_id='"..rating_id.."' and resource_status='3' ";
--获奖作品
local award_count_sql = " select count(*) as award_count from t_rating_resource where rating_id='"..rating_id.."' and award_id in (1,2,3,4) ";

--参赛人数统计
local person_count_sql_res = DBUtil: querySingleSql(person_count_sql);
if not person_count_sql_res then
	return false;
end	
local person_count_sql_count = person_count_sql_res[1]["person_count"];

--参赛作品统计
local resource_count_sql_res = DBUtil: querySingleSql(resource_count_sql);
if not resource_count_sql_res then
	return false;
end	
local resource_count_sql_count = resource_count_sql_res[1]["resource_count"];

--入围作品统计
local lis_count_sql_res = DBUtil: querySingleSql(lis_count_sql);
if not lis_count_sql_res then
	return false;
end	
local lis_count_sql_count = lis_count_sql_res[1]["lis_count"];

--获奖作品统计
local award_count_sql_res = DBUtil: querySingleSql(award_count_sql);
if not award_count_sql_res then
	return false;
end	
local award_count_sql_count = award_count_sql_res[1]["award_count"];

local resultDate = {};
resultDate.person_count_sql_count = person_count_sql_count;
resultDate.resource_count_sql_count = resource_count_sql_count;
resultDate.lis_count_sql_count = lis_count_sql_count;
resultDate.award_count_sql_count = award_count_sql_count;
resultDate.success = true;
ngx.print(encodeJson(resultDate));

