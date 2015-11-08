-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询需要审核试题列表
-- 作者：刘全锋
-- 日期：2015年8月28日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"


local check_status = args["check_status"] 
local version_id = args["version_id"]
local all_version_ids = args["all_version_ids"]
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]

	
--判断是否有check_status参数
if check_status == nil  then
    ngx.say("{\"success\":false,\"info\":\"check_status参数错误！\"}")
    return
end


--判断是否有version_id参数
if version_id==nil or version_id =="" then
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

local conditionSegement = "	from t_tk_question_info WHERE  b_delete=0 and group_id=2 ";

if version_id == "0" then 
	conditionSegement= conditionSegement.." and scheme_id_int in (" ..all_version_ids..") ";
else
	conditionSegement= conditionSegement.." and scheme_id_int="..version_id;
end


if check_status==""  then
	conditionSegement= conditionSegement.." and check_status in (1,2,3)";
else
	conditionSegement= conditionSegement.." and check_status="..check_status;
end


local countSql  = "select count(1) as row_count " .. conditionSegement;


local countRes  = db:query(countSql);
if not countRes then
	return false;
end

local totalRow  = countRes[1]["row_count"];
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
local offset    = pageSize*pageNumber-pageSize;
local limit     = pageSize;


local querySql = "select id,json_question,create_person,check_status "..conditionSegement.. " order by id desc limit "..offset..","..limit;



local queryRes  = db: query(querySql);
if not queryRes then
	return false;
end


local resultList = {};
for index, record in ipairs(queryRes) do
	local tempRecord = {};
	tempRecord["id"]     			= record["id"];
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
