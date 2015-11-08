--[[
统计学校的资源建设情况
@Author  chenxg
@Date    2015-05-18
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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
--参数 
local school_id = args["school_id"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]
local start_time = args["start_time"]
local end_time = args["end_time"]
--0首次统计 1总体统计 2学段学科统计 3学段学科教师统计 4教师资源列表统计
local dtype = args["dtype"]

--判断参数是否为空
if not school_id or string.len(school_id) == 0 
	or not dtype or string.len(dtype) == 0 
  then
    say("{\"success\":false,\"info\":\"school_id or dtype 参数错误！\"}")
    return
end

local timeStr = ""
if start_time ~= "" and end_time ~= "" then
	timeStr = " and t.CREATE_TIME between '"..start_time.." 00:00:00' and '"..end_time.." 23:59:59' "
end

local returnjson = {}

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--删除统计表中该学校以前的数据
if dtype == "0" then
	local delete_sql = "delete from t_resource_tongji where BUREAU_ID = "..school_id..""
	mysql_db:query(delete_sql)

	--将该学校上传的资源写入资源统计表
	local insertSql = "insert into t_resource_tongji(RESOURCE_ID_INT,PERSON_ID,PERSON_NAME,stage_id,SUBJECT_NAME,RESOURCE_TITLE,RESOURCE_SIZE_INT,RESOURCE_SIZE,CREATE_TIME,BUREAU_ID) select r.RESOURCE_ID_INT,p.PERSON_ID,p.PERSON_NAME,s.stage_id,su.SUBJECT_NAME,r.RESOURCE_TITLE,r.RESOURCE_SIZE_INT,r.RESOURCE_SIZE,r.CREATE_TIME,o.BUREAU_ID from t_base_person p,t_base_organization o ,t_resource_scheme s,t_resource_base r ,t_dm_subject su where r.SCHEME_ID = s.SCHEME_ID and p.PERSON_ID = r.CREATE_PERSON and p.PERSON_ID = r.CREATE_PERSON and o.ORG_ID = p.ORG_ID and s.SUBJECT_ID = su.SUBJECT_ID and p.BUREAU_ID = "..school_id..timeStr.." ";		
	mysql_db:query(insertSql)
	
elseif dtype == "1" then--查询该学校资源的总体情况
	local sch_sql = "select o.ORG_NAME as 学校名称,count(1) as 数量,case when SUM(RESOURCE_SIZE_INT) / (1024 * 1024 * 1000) >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / (1024 * 1024 * 1000), 2) , 'G') when SUM(RESOURCE_SIZE_INT) / (1024 * 1024) >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / (1024 * 1024), 2) , 'M') when SUM(RESOURCE_SIZE_INT) / 1024 >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / 1024, 2) ,'K') else  CONCAT(SUM(RESOURCE_SIZE_INT),'B')end as  容量 from t_resource_tongji t LEFT JOIN t_base_organization o on o.ORG_ID = t.BUREAU_ID where t.BUREAU_ID = "..school_id..timeStr.." GROUP BY 学校名称 "
	local sch_result, err, errno, sqlstate = mysql_db:query(sch_sql);
	if not sch_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sch_sql.."<====countsql");
		return;
	end
	if #sch_result <1 then
		local orglist
		local res_org = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds?ids=".. school_id)

		if res_org.status == 200 then
			orglist = (cjson.decode(res_org.body))
		else
			say("{\"success\":false,\"info\":\"查询失败！\"}")
		end
		
		ngx.log(ngx.ERR, "cxg_log==="..orglist.list[1]["ORG_NAME"].."<====countsql");
		local sch_name = orglist.list[1]["ORG_NAME"]
		local res_sum = 0
		local res_size = 0
		returnjson.sch_name = sch_name
		returnjson.res_sum = res_sum
		returnjson.res_size = res_size
	else
		local sch_name = sch_result[1]["学校名称"]
		local res_sum = sch_result[1]["数量"]
		local res_size = sch_result[1]["容量"]
		returnjson.sch_name = sch_name
		returnjson.res_sum = res_sum
		returnjson.res_size = res_size	
	end
elseif dtype == "2" then--查询该学校学段学科资源情况

	if not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	  then
		say("{\"success\":false,\"info\":\"pageSize or pageNumber 参数错误！\"}")
		return
	end
	
	local sql2 = "select o.ORG_NAME as 学校名称,CASE	when t.stage_id = 4 then '小学'	when t.stage_id = 5 then '初中'	when t.stage_id = 6 then '高中'end as 学段,t.SUBJECT_NAME as 学科,count(1) as 数量,case when SUM(RESOURCE_SIZE_INT) / (1024 * 1024 * 1000) >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / (1024 * 1024 * 1000), 2) , 'G') when SUM(RESOURCE_SIZE_INT) / (1024 * 1024) >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / (1024 * 1024), 2) , 'M') when SUM(RESOURCE_SIZE_INT) / 1024 >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / 1024, 2) ,'K') else  CONCAT(SUM(RESOURCE_SIZE_INT),'B') end as  容量 from t_resource_tongji t LEFT JOIN t_base_organization o on o.ORG_ID = t.BUREAU_ID where t.BUREAU_ID = "..school_id..timeStr.." GROUP BY 学校名称,学段,学科 order by 学校名称,学段,学科 "
	
	local limit = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""
	
	local res_sql = sql2 .. limit
	
	local count_result, err, errno, sqlstate = mysql_db:query(sql2);
	if not count_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sql2);
		return;
	end
	local res_result, err, errno, sqlstate = mysql_db:query(res_sql);
	if not res_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sql2);
		return;
	end
	
	pageSize = tonumber(pageSize)
	pageNumber = tonumber(pageNumber)
	local totalRow = #count_result
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	returnjson.totalPage = totalPage
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	returnjson.totalRow = totalRow
	
	local sch_res_list = {}
	for i=1,#res_result do
		local res_list = {}
		res_list.sch_name = res_result[i]["学校名称"]
		res_list.stage_name = res_result[i]["学段"]
		res_list.subject_name = res_result[i]["学科"]
		res_list.res_sum = res_result[i]["数量"]
		res_list.res_size = res_result[i]["容量"]
		sch_res_list[i] = res_list
	end
	returnjson.sch_res_list = sch_res_list

elseif dtype == "3" then--查询噶学校学段学科教师的资源建设情况
	if not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	  then
		say("{\"success\":false,\"info\":\"pageSize or pageNumber 参数错误！\"}")
		return
	end
		
	local sql3 = "select o.ORG_NAME as 学校名称, CASE when t.stage_id = 4 then '小学'	when t.stage_id = 5 then '初中'	when t.stage_id = 6 then '高中' end as 学段,t.SUBJECT_NAME as 学科,t.PERSON_NAME as 教师姓名,count(1) as 数量,case when SUM(RESOURCE_SIZE_INT) / (1024 * 1024 * 1000) >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / (1024 * 1024 * 1000), 2) , 'G') when SUM(RESOURCE_SIZE_INT) / (1024 * 1024) >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / (1024 * 1024), 2) , 'M') when SUM(RESOURCE_SIZE_INT) / 1024 >= 1 then  CONCAT(round(SUM(RESOURCE_SIZE_INT) / 1024, 2) ,'K') else  CONCAT(SUM(RESOURCE_SIZE_INT),'B') end as  容量 from t_resource_tongji t LEFT JOIN t_base_organization o on o.ORG_ID = t.BUREAU_ID where t.BUREAU_ID = "..school_id..timeStr.." GROUP BY 学校名称,教师姓名,学段,学科 ORDER BY 学校名称,学段,学科,教师姓名 "
	
	local limit = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""
	
	local res_sql = sql3 .. limit
	
	local count_result, err, errno, sqlstate = mysql_db:query(sql3);
	if not count_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sql3);
		return;
	end
	local res_result, err, errno, sqlstate = mysql_db:query(res_sql);
	if not res_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sql3);
		return;
	end
	
	pageSize = tonumber(pageSize)
	pageNumber = tonumber(pageNumber)
	local totalRow = #count_result
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	returnjson.totalPage = totalPage
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	returnjson.totalRow = totalRow
	
	local sch_res_list = {}
	for i=1,#res_result do
		local res_list = {}
		res_list.sch_name = res_result[i]["学校名称"]
		res_list.stage_name = res_result[i]["学段"]
		res_list.subject_name = res_result[i]["学科"]
		res_list.person_name = res_result[i]["教师姓名"]
		res_list.res_sum = res_result[i]["数量"]
		res_list.res_size = res_result[i]["容量"]
		sch_res_list[i] = res_list
	end
	returnjson.sch_res_list = sch_res_list

elseif dtype == "4" then--查询该学校下资源的详细建设情况
	if not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	  then
		say("{\"success\":false,\"info\":\"pageSize or pageNumber 参数错误！\"}")
		return
	end
	
	local sql4 = "select o.ORG_NAME as 学校名称,CASE when t.stage_id = 4 then '小学'	when t.stage_id = 5 then '初中' when t.stage_id = 6 then '高中' end as 学段,t.SUBJECT_NAME as 学科,t.PERSON_NAME as 教师姓名,RESOURCE_TITLE as 资源名称,t.CREATE_TIME as 上传时间 from t_resource_tongji t LEFT JOIN t_base_organization o on o.ORG_ID = t.BUREAU_ID where t.BUREAU_ID = "..school_id..timeStr.." order by 学校名称,学段,学科,教师姓名 "
	
	local limit = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""
	
	local res_sql = sql4 .. limit
	
	local count_result, err, errno, sqlstate = mysql_db:query(sql4);
	if not count_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sql4);
		return;
	end
	local res_result, err, errno, sqlstate = mysql_db:query(res_sql);
	if not res_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "cxg_log==="..sql4);
		return;
	end
	
	pageSize = tonumber(pageSize)
	pageNumber = tonumber(pageNumber)
	local totalRow = #count_result
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	returnjson.totalPage = totalPage
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	returnjson.totalRow = totalRow
	
	local sch_res_list = {}
	for i=1,#res_result do
		local res_list = {}
		res_list.sch_name = res_result[i]["学校名称"]
		res_list.stage_name = res_result[i]["学段"]
		res_list.subject_name = res_result[i]["学科"]
		res_list.person_name = res_result[i]["教师姓名"]
		res_list.res_title = res_result[i]["资源名称"]
		res_list.res_time = res_result[i]["上传时间"]
		sch_res_list[i] = res_list
	end
	returnjson.sch_res_list = sch_res_list
end
--return
returnjson.success = true
say(cjson.encode(returnjson))


--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
