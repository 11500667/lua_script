
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询重复试题列表
-- 作者：刘全锋
-- 日期：2015年8月28日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();

local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

local all_version_ids = args["all_version_ids"]
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]
local version_id = args["version_id"]


-- 判断是否有version_id参数
if version_id == nil or version_id =="" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
    return
end


-- 判断是否有all_version_ids参数
if all_version_ids==nil or all_version_ids =="" then
    ngx.say("{\"success\":false,\"info\":\"all_version_ids参数错误！\"}")
    return
end


-- 判断是否有pageNumber参数
if pageNumber==nil or pageNumber =="" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end


-- 判断是否有pageSize参数
if pageSize == nil or pageSize =="" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end


local conditionSegement = "	From (SELECT i.id,i.question_id_char,i.json_question,i.create_person,i.update_ts,b.content_md5_new_unique FROM t_tk_question_info i LEFT JOIN t_tk_question_base b ON i.question_id_char = b.question_id_char WHERE i.create_person=1 and i.group_id=1 and i.b_delete=0 and b.b_repeat=0 and i.question_id_char IN(SELECT question_id_char FROM t_tk_question_base WHERE content_md5_new_unique IN(SELECT content_md5_new_unique FROM t_tk_question_base where b_repeat=0  GROUP BY content_md5_new_unique HAVING COUNT(*)>1)) ";


if version_id == "0" then
    conditionSegement= conditionSegement.." and i.scheme_id_int in (" ..all_version_ids..") ";
else
    conditionSegement= conditionSegement.." and i.scheme_id_int="..version_id;
end

conditionSegement= conditionSegement.." group by b.content_md5_new_unique,i.structure_id_int having count(*) > 1) tem";

local countSql  = "select count(1) as row_count" .. conditionSegement;

local countRes  = db:query(countSql);
if not countRes then
	return false;
end

local totalRow  = countRes[1]["row_count"];
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
local offset    = pageSize*pageNumber-pageSize;
local limit     = pageSize;


local querySql = "select tem.id,tem.json_question,tem.create_person,tem.content_md5_new_unique"..conditionSegement.. " group by tem.question_id_char order by tem.id desc limit "..offset..","..limit;

local queryRes  = db: query(querySql);
if not queryRes then
	return false;
end

local resultList = {};
for index, record in ipairs(queryRes) do
	local tempRecord = {};
	tempRecord["id"]     			= record["id"];
    tempRecord["content_md5_new_unique"]     = record["content_md5_new_unique"];
	tempRecord["json_question"]   	= cjson.decode(ngx.decode_base64(record["json_question"]));
	tempRecord["create_person"]   	= record["create_person"];
	tempRecord["check_status"]  	= record["check_status"];
	table.insert(resultList, tempRecord);
end

DBUtil: keepDbAlive(db);


local resultJsonObj		= {};
resultJsonObj.success  = true;	
resultJsonObj.totalRow   = tonumber(totalRow);
resultJsonObj.totalPage  = totalPage;
resultJsonObj.pageNumber = tonumber(pageNumber);
resultJsonObj.pageSize 	 = tonumber(pageSize);
resultJsonObj.list 		= resultList;


ngx.say(encodeJson(resultJsonObj));
