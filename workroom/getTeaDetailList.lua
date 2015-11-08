--[[
根据教师全拼,名字获取教师信息列表，用于检索教师，添加名师使用
@Author  陈续刚
@Date    2015-09-06
--]]

local say = ngx.say
local quote = ngx.quote_sql_str

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--引用模块
local cjson = require "cjson"

--获得get请求参数
local cookie_province_id = tonumber(ngx.var.cookie_background_province_id)
local cookie_city_id = tonumber(ngx.var.cookie_background_city_id)
local cookie_district_id = tonumber(ngx.var.cookie_background_district_id)

local bureau_id = 0;
bureau_id = cookie_district_id;
if 0 == bureau_id then
	bureau_id = cookie_city_id;
elseif 0 == bureau_id then
	bureau_id = cookie_province_id;
end
--pageNumber
local pageNumber = tonumber(args["page"]);
-- 每页显示行数 pageSize
local pageSize =  tonumber(args["rows"]);

local keyword = ngx.unescape_uri(args["searchTerm"]);
if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..""
	else
		keyword = ""
	end
end


if  not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

if pageNumber == 0 then
	pageNumber = 1
end


-----------------------------------
--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(15000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"连接数据库失败\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end


local wheresql=" ";
local keywordsql = " "
if bureau_id >300000 then
	wheresql = "P.DISTRICT_ID = "..bureau_id.." ";
elseif bureau_id >200000 then
	wheresql = "P.CITY_ID = "..bureau_id.." ";
else
	wheresql = "P.PROVINCE_ID =  "..bureau_id.." ";
end
if keyword ~= "" then
	keywordsql = " and (P.QP LIKE "..quote("%"..keyword.."%").." OR P.PERSON_NAME LIKE "..quote("%"..keyword.."%")..") "
end
local limit_sql = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""

local person_sql = "SELECT P.PERSON_ID as teacher_id,concat(P.PERSON_NAME,'(',LP.LOGIN_NAME,')') as teacher_name,lower(P.QP) QP,P.PROVINCE_ID,P.CITY_ID,P.DISTRICT_ID,P.BUREAU_ID as school_id,O.ORG_NAME as school_name,ifnull(SU.SUBJECT_ID,0) as subject_id,ifnull(SU.SUBJECT_NAME,'暂无') as subject_name,ifnull(ST.STAGE_ID,0) as stage_id,ifnull(ST.STAGE_NAME,'暂无') as stage_name ";

local count_sql = "SELECT P.PERSON_ID ";

local next_sql = " FROM T_BASE_PERSON P LEFT JOIN T_SYS_LOGINPERSON LP ON LP.PERSON_ID = P.PERSON_ID AND LP.IDENTITY_ID = P.IDENTITY_ID LEFT JOIN T_BASE_PERSON_SUBJECT PS ON PS.PERSON_ID = P.PERSON_ID LEFT JOIN T_DM_SUBJECT SU ON SU.SUBJECT_ID = PS.SUBJECT_ID LEFT JOIN T_DM_STAGE ST ON ST.STAGE_ID = SU.STAGE_ID LEFT JOIN T_BASE_ORGANIZATION O ON O.ORG_ID = P.BUREAU_ID WHERE "..wheresql..keywordsql.."  AND P.IDENTITY_ID=5 ";

local next_sql2 = " FROM T_BASE_PERSON P WHERE "..wheresql..keywordsql.."  AND P.IDENTITY_ID=5 ";


ngx.log(ngx.ERR, "cxg_log =====>"..count_sql..next_sql2);
local person_count, err, errno, sqlstate = db:query(count_sql..next_sql);
local person_list, err, errno, sqlstate = db:query(person_sql..next_sql..limit_sql);
if not person_list then
	ngx.say("{\"success\":false,\"info\":\"查询教师数据失败！\"}");
	return;
end

local totalRow = 0
if person_count and #person_count>=0 then
	totalRow = #person_count
end
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)


local returnjson = {}
returnjson.success = true

returnjson.rows = person_list
returnjson.records = totalRow
returnjson.total = totalPage
returnjson.page = pageNumber
--returnjson.pageSize = pageSize

-----------------------------------

cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
