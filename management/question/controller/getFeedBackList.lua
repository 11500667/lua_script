
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

local pageNumber = args["pageNumber"];
local pageSize = args["pageSize"];
local feedback_status = args["feedback_status"];
local version_id = args["version_id"]
local all_version_ids = args["all_version_ids"];


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


-- 判断是否有version_id参数
if version_id == nil or version_id =="" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
    return
end



-- 判断是否有all_version_ids参数
if all_version_ids == nil or all_version_ids =="" then
    ngx.say("{\"success\":false,\"info\":\"all_version_ids参数错误！\"}")
    return
end



local conditionSegement = "	from t_base_feedback f inner join t_tk_question_info i on f.target_id_char=i.question_id_char where f.target_type=2 and i.create_person=1 and i.b_delete=0";

-- 判断是否有feedback_status参数
if feedback_status ~= nil then
    conditionSegement = conditionSegement.." and feedback_status="..tonumber(feedback_status);
end


if version_id == "0" then
    conditionSegement= conditionSegement.." and scheme_id_int in (" ..all_version_ids..") ";
else
    conditionSegement= conditionSegement.." and scheme_id_int="..version_id;
end



conditionSegement = conditionSegement.." GROUP BY feedback_id";

local countSql  = "select count(1) as row_count from (select feedback_id " .. conditionSegement..") tem";

local countRes  = db:query(countSql);
if not countRes then
	return false;
end

local totalRow  = countRes[1]["row_count"];
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
local offset    = pageSize*pageNumber-pageSize;
local limit     = pageSize;


local querySql = "select f.feedback_id,f.target_id,f.person_name,f.feedback_time,f.feedback_status,i.id,i.json_question"..conditionSegement.. " order by f.feedback_id desc limit "..offset..","..limit;


local queryRes  = db: query(querySql);
if not queryRes then
	return false;
end


local resultList = {};
for index, record in ipairs(queryRes) do
	local tempRecord = {};
    tempRecord["feedback_id"]       = record["feedback_id"];
	tempRecord["target_id"]     	= record["target_id"];
    tempRecord["person_name"]       = record["person_name"];
    tempRecord["feedback_time"]   	= record["feedback_time"];
    tempRecord["feedback_status"]  	= record["feedback_status"];
    tempRecord["id"]               	= record["id"];
	tempRecord["json_question"]   	= cjson.decode(ngx.decode_base64(record["json_question"]));
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
