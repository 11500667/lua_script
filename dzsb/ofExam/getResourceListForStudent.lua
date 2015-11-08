#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-09-02
#描述：学生获取下载列表 
 参数：
		pageSize:每页显示资源个数
		identity_id:人员身份ID
		pageNumber:当前页数
		person_id:人员ID
		subject_id：学科ID，要获取哪科的下载列表，如果是-1 ，则代表全部学科
		keyword：搜索关键字，如果没有搜索条件，默认为””
		type：要获取下载课件的备课类型，102学案 104电子书 107试卷，-1是三合一
		sort：排序类型，按照上传时间排序，1为降序，2为升序

 涉及到的表：t_bag_sjstate、t_resource_sendstudent、t_bag_resource_info（弃用）改为t_resource_info
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local identity_id = args["identity_id"];
-- 判断是否有identity_id参数
if identity_id == nil then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}");
    return;
end
-- 判断是否是学生
if identity_id == 5 then
	ngx.say("{\"success\":false,\"info\":\"identity_id参数身份错误！\"}");
	return;
end

local pageSize = tonumber(args["pageSize"]);
-- 判断是否有pageSize参数
if pageSize == nil then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}");
    return;
end

local pageNumber = tonumber(args["pageNumber"]);
-- 判断是否有pageNumber参数
if pageNumber==nil  then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}");
    return;
end

local person_id = tonumber(args["person_id"]);
-- 判断是否有person_id参数
if person_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}");
    return;
end

local subject_id = tonumber(args["subject_id"]);
-- 判断是否有subject_id参数
if subject_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}");
    return;
end

local sort = tonumber(args["sort"]);
--判断是否有sort参数
if sort == nil  then
    ngx.say("{\"success\":false,\"info\":\"sort参数错误！\"}");
    return;
end

local keyword = tostring(args["keyword"]);
-- 判断是否有keyword参数
if keyword == nil then
    ngx.say("{\"success\":false,\"info\":\"keyword参数错误！\"}");
    return;
end

local resource_type = tonumber(args["type"]);
-- 判断是否有type参数
if resource_type == nil  then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}");
    return;
end

--2.连接数据库
local mysql = require "resty.mysql";
local db = mysql:new();
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--3.连接redis服务器
local redis = require "resty.redis";
local cache = redis:new();
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}");
    return;
end

--4.连接SSDB
local ssdb = require "resty.ssdb";
local ssdb_db = ssdb:new();
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port);
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
    return;
end

-- 5.查询
local sql_first_student_id = "SELECT (SELECT is_exam FROM t_bag_sjstate WHERE class_id = t1.class_id AND resource_id = t2.resource_id_int) AS is_exam ,t2.subject_id as subject_id,t2.resource_id_int as resource_id,t2.resource_title as resource_title,t2.update_ts,t2.file_id as file_id,t2.create_time as create_time,t2.person_id as person_id,t3.state_id as is_open ,t1.id,t2.resource_size  FROM t_resource_sendstudent AS t1 INNER JOIN t_resource_info AS t2 ON t1.resource_id = t2.resource_id_int INNER JOIN t_bag_sjstate t3 ON t3.resource_id = t1.resource_id AND t3.class_id = t1.class_id WHERE t2.group_id=2 and t2.release_status in (1,3) and t2.bk_type="..resource_type; 
local sql_xuean = "SELECT t2.bk_type,t2.subject_id as subject_id,t2.resource_id_int as resource_id,t2.resource_title as resource_title,t2.update_ts,t2.file_id as file_id,t2.create_time as create_time,t2.person_id as person_id,t1.state_id,t1.id,t2.resource_size FROM t_resource_sendstudent AS t1 INNER JOIN t_resource_info AS t2 ON t1.resource_id = t2.resource_id_int  WHERE t2.group_id=2 and t2.release_status in (1,3) and t2.bk_type="..resource_type;
local sql_first_student_id_count = "select count(*) as count from t_resource_sendstudent AS t1 INNER JOIN t_resource_info AS t2 ON t1.resource_id = t2.resource_id_int INNER JOIN t_bag_sjstate t3 ON t3.resource_id = t1.resource_id AND t3.class_id = t1.class_id WHERE  t2.group_id=2 and t2.bk_type="..resource_type;
local sql_xuean_count = "select count(*) as count from  t_resource_sendstudent AS t1 INNER JOIN t_resource_info AS t2 ON t1.resource_id = t2.resource_id_int WHERE t2.group_id=2 and t2.release_status in (1,3) and t2.bk_type="..resource_type;

local sql_subject_id = "";
local sql_keyword = "";
local sql_person_id = "";
local sql_sort = "";

--拼接学科
if subject_id ~="-1" then
	sql_subject_id = " and subject_id="..subject_id;
end

--拼接关键字ngx.decode_base64(keyword)
if #keyword ~= 0 then
	sql_keyword = " and resource_title like '%".. keyword.."%'";
end

--拼接人
sql_person_id = " and t1.student_id="..person_id;

--拼接排序
if sort == 1 then
   sql_sort = " order by ts desc";
elseif sort == 2 then
   sql_sort = " order by ts asc";
end 

local sql = "";
local sql_count_end = "";

if resource_type == 102 or resource_type == 104  then
    --查询的是学案、电子书
	sql =  sql_xuean..sql_subject_id..sql_keyword..sql_person_id..sql_sort;
	sql_count_end = sql_xuean_count..sql_subject_id..sql_keyword..sql_person_id..sql_sort;
end

if resource_type == 107 then 
	-- 查询的是试卷
	sql = sql_first_student_id..sql_subject_id..sql_keyword..sql_person_id..sql_sort;
	sql_count_end = sql_first_student_id_count..sql_subject_id..sql_keyword..sql_person_id..sql_sort;
end

local offset = pageSize * pageNumber - pageSize;
local limit = pageSize;

local sql_limit = " limit "..offset..","..limit;
local res, err, errno, sqlstate = db:query(sql..sql_limit);
if not res then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

local res_count, err, errno, sqlstate = db:query(sql_count_end);
if not res_count then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询资源数量出错！\"}");
    return;
end

local totalRow = res_count[1]["count"];
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize);
local responseObj = {};
local res_tab = {};
responseObj.success = true;
for i=1, #res do
    local tab = {};
	tab.resource_id = res[i]["resource_id"];
	tab.resource_title = res[i]["resource_title"];
	tab.person_id = res[i]["person_id"];
	local person_name = cache:hget("person_"..res[i]["person_id"].."_5","person_name");
	tab.person_name = person_name;
	tab.create_time = res[i]["create_time"];
	tab.file_id = res[i]["file_id"];
	tab.update_ts = res[i]["update_ts"];
	tab.subject_id = res[i]["subject_id"];
	
	if resource_type == 107 then
		tab.id = res[i]["id"];
		tab.is_exam = res[i]["is_exam"];
		tab.is_open = res[i]["is_open"];
		tab.file_id = res[i]["file_id"];
		tab.resource_size = res[i]["resource_size"];
	else
		local res_info_is_summary = ssdb_db:multi_hget("teach_resource_"..res[i]["resource_id"],"is_summary");
		tab.is_summary = res_info_is_summary[2];
	end
	
	res_tab[i] = tab;
end

responseObj.list= res_tab;
responseObj.totalPage = totalPage;
responseObj.totalRow = totalRow;
responseObj.pageNumber = pageNumber;
responseObj.pageSize = pageSize;

-- 6.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

--7.redis、db、ssdb放回连接池
cache:set_keepalive(0,v_pool_size);
db:set_keepalive(0,v_pool_size);
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say(responseJson);
