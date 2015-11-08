local DBUtil = require "common.DBUtil";
local args = getParams();
-------------------------------前台输入--------------------------------------
--rating_id
local ratingId = args["rating_id"];
--id
local id = args["id"];
-------------------------------验证前台必须输入------------------------------
if ratingId == nil or ratingId == "" then
	ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}");
	return;
end
if id == nil or id == "" then
	ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}");
	return;
end
-------------------------------后台获取--------------------------------------
local personId = getCookieByName("person_id");
------------------------------------------------------------------------------
local querySql = "select count(*) as count from t_dswk_vote ";
local wheresql = " where RATING_ID="..ratingId.." and RATING_RESOURCE_ID="..id.." and PERSON_ID="..personId.."";
querySql = querySql..wheresql;
ngx.log(ngx.ERR, "===> 查询当前人是否已经对该资源投票 ===> ", querySql);
local querysql_res = DBUtil: querySingleSql(querySql);
local result = {};
if tonumber(querysql_res[1]["count"]) == 0 then
	result.success = true;
	result.info = "还未投票";
else
	result.success = false;
	result.info = "请不要重复投票！"
end
ngx.print(encodeJson(result));

