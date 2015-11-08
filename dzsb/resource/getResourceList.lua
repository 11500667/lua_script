#ngx.header.content_type = "text/plain;charset=utf-8"

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local pageSize = args["pageSize"]

-- 判断是否有pageSize参数
if pageSize == nil then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end


local identity_id = args["identity_id"]

-- 判断是否有identity_id参数
if identity_id == nil then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

local pageNumber = args["pageNumber"]
-- 判断是否有pageNumber参数
if pageNumber==nil  then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end

local person_id = args["person_id"]
-- 判断是否有person_id参数
if person_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

local subject_id = args["subject_id"]

-- 判断是否有subject_id参数
if subject_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local sort = args["sort"]
--判断是否有sort参数
if sort == nil  then
    ngx.say("{\"success\":false,\"info\":\"sort参数错误！\"}")
    return
end
--[[
local sql_subject_id = "";
if subject_id ~="-1" then
   sql_subject_id = "AND SUBJECT_ID = "..subject_id;
end
]]
local keyword = args["keyword"];
-- 判断是否有keyword参数
if keyword == nil then
    ngx.say("{\"success\":false,\"info\":\"keyword参数错误！\"}")
    return
end

local resource_type = args["type"];
-- 判断是否有type参数
if resource_type == nil  then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end

local sql_first = "SELECT subject_id,resource_id,resource_title,file_id,create_time,create_person,is_summary,update_logo FROM t_bag_resource_info where b_use=1 and resource_category ="..resource_type;
local sql_first_student_id = "SELECT (SELECT is_exam FROM t_bag_sjstate WHERE class_id = t1.class_id AND resource_id = t2.resource_id) AS is_exam ,t2.subject_id as subject_id,t2.resource_id as resource_id,t2.resource_title as resource_title,t2.update_logo,t2.file_id as file_id,t2.create_time as create_time,t2.create_person as create_person,t3.state_id as is_open ,t1.id,t2.resource_size  FROM t_resource_sendstudent AS t1 INNER JOIN t_bag_resource_info AS t2 ON t1.resource_id = t2.resource_id INNER JOIN t_bag_sjstate t3 ON t3.resource_id = t1.resource_id AND t3.class_id = t1.class_id WHERE t2.b_use=1 and t2.resource_category = "..resource_type;
local sql_first_teacher_ceshi = "select a.subject_id as subject_id,a.resource_title,ifnull(b.is_exam,0) as is_exam,a.file_id,a.update_logo,a.create_time,a.create_person,a.resource_id,a.resource_size from t_bag_resource_info a left join  (select * from t_bag_sjstate WHERE state_id=1 group by resource_id) b on b.resource_id=a.resource_id WHERE a.b_use =1 and a.resource_category = "..resource_type;
local sql_xuean = "SELECT t2.is_summary as is_summary,t2.resource_category,t2.subject_id as subject_id,t2.resource_id as resource_id,t2.resource_title as resource_title,t2.update_logo,t2.file_id as file_id,t2.create_time as create_time,t2.create_person as create_person,t1.state_id,t1.id,t2.resource_size FROM t_resource_sendstudent AS t1 INNER JOIN t_bag_resource_info AS t2 ON t1.resource_id = t2.resource_id  WHERE t2.b_use=1 and t2.resource_category = "..resource_type;


local sql_first_count = "select count(*) as count from t_bag_resource_info where b_use = 1 and resource_category ="..resource_type;
local sql_first_student_id_count = "select count(*) as count from t_resource_sendstudent AS t1 INNER JOIN t_bag_resource_info AS t2 ON t1.resource_id = t2.resource_id INNER JOIN t_bag_sjstate t3 ON t3.resource_id = t1.resource_id AND t3.class_id = t1.class_id WHERE t2.resource_category = "..resource_type;
local sql_first_teacher_ceshi_count = "select count(*) as count from t_bag_resource_info a left join  (select * from t_bag_sjstate WHERE state_id=1 group by resource_id) b on b.resource_id=a.resource_id WHERE a.b_use = 1 and a.resource_category = "..resource_type;
local sql_xuean_count = "select count(*) as count from  t_resource_sendstudent AS t1 INNER JOIN t_bag_resource_info AS t2 ON t1.resource_id = t2.resource_id  WHERE t2.b_use = 1 and  t2.resource_category = "..resource_type;


local sql_subject_id = "";
local sql_keyword = "";
local sql_person = "";
local sql_sort = "";
local sql_teachers = "";
--拼接学科
if subject_id ~="-1" then
	sql_subject_id = " and subject_id = "..subject_id;
end
--拼接关键字		   
if #keyword ~= 0 then
	sql_keyword = " and resource_title like '%".. ngx.decode_base64(keyword).."%' ";
end
--拼接人

if identity_id == "5" then
   sql_person = " and create_person="..person_id;

else
   sql_person = " and t1.student_id="..person_id;

end
--拼接排序

if sort =="1" then
   sql_sort = " order by ts desc";
 elseif sort == "2" then
   sql_sort = " order by ts asc";
end 

local sql = "";
local sql_count_end = "";

-- if resource_type=="4" then
    -- --查询的是电子书

	 -- if identity_id == "5" then
       -- sql = sql_first..sql_subject_id..sql_keyword..sql_sort;
	   -- sql_count_end = sql_first_count..sql_subject_id..sql_keyword..sql_sort;
	 -- else 
	   -- sql =  sql_first..sql_subject_id..sql_keyword..sql_sort;
	   -- sql_count_end = sql_first_count..sql_subject_id..sql_keyword..sql_sort;
     -- end
 -- end

if resource_type == "2" or resource_type == "4"  then
     --查询的是学案，需要分区是学生还是老师
     --如果是老师
     if identity_id == "5" then
      sql = sql_first..sql_subject_id..sql_keyword..sql_person..sql_sort;
	  sql_count_end = sql_first_count..sql_subject_id..sql_keyword..sql_person..sql_sort;
	 else 
	   sql =  sql_xuean..sql_subject_id..sql_keyword..sql_person..sql_sort;
	   sql_count_end = sql_xuean_count..sql_subject_id..sql_keyword..sql_person..sql_sort;
     end
end

if resource_type == "7" then 
   if identity_id == "5" then
       sql = sql_first_teacher_ceshi..sql_subject_id..sql_keyword..sql_person..sql_sort;
	   sql_count_end = sql_first_teacher_ceshi_count..sql_subject_id..sql_keyword..sql_person..sql_sort;
	 else 
	   sql = sql_first_student_id..sql_subject_id..sql_keyword..sql_person..sql_sort;
	    sql_count_end = sql_first_student_id_count..sql_subject_id..sql_keyword..sql_person..sql_sort;
     end
   
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*pageSize

local sql_limit = " limit "..offset..","..limit;
--ngx.log(ngx.ERR,"sql_limit=========="..sql..sql_limit);
local res = db:query(sql..sql_limit);
local res_count = db:query(sql_count_end);

local totalRow = res_count[1]["count"];
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
local responseObj = {};
local res_tab = {};
 responseObj.success = true;
for i=1,#res do
     local tab = {};
	 if resource_type == "7" then
	     if identity_id == "5" then 
		    --老师
	        tab.resource_id = res[i]["resource_id"];
		    tab.id = res[i]["resource_id"];
			tab.resource_title =  res[i]["resource_title"];
			tab.create_person =  res[i]["create_person"];
			local person_name = cache:hget("person_"..res[i]["create_person"].."_5","person_name")
	        tab.person_name = person_name;
			tab.resource_size =  res[i]["resource_size"];
			tab.file_id =  res[i]["file_id"];
			tab.update_logo =  res[i]["update_logo"];
			tab.create_time =  res[i]["create_time"];
			tab.is_exam =  res[i]["is_exam"];
			tab.subject_id =  res[i]["subject_id"];
			
			res_tab[i]=tab
		else
		   --学生
		    tab.resource_id = res[i]["resource_id"];
		    tab.id = res[i]["id"];
		    tab.resource_title =  res[i]["resource_title"];
			tab.is_exam =  res[i]["is_exam"];
			tab.is_open =  res[i]["is_open"];
			tab.create_person =  res[i]["create_person"];
			local person_name = cache:hget("person_"..res[i]["create_person"].."_5","person_name")
	        tab.person_name = person_name;
			tab.create_time =  res[i]["create_time"];
			tab.file_id =  res[i]["file_id"];
			tab.update_logo =  res[i]["update_logo"];
			tab.resource_size =  res[i]["resource_size"];
			tab.subject_id =  res[i]["subject_id"];
              res_tab[i]=tab
		end
		 
	 else
	   tab.resource_id =  res[i]["resource_id"];
	   tab.resource_title =  res[i]["resource_title"];
	   tab.file_id =  res[i]["file_id"];
	   tab.create_time =  res[i]["create_time"];
	   tab.create_person =  res[i]["create_person"];
	   --根据人员id获得人员姓名
	   local person_name = cache:hget("person_"..res[i]["create_person"].."_5","person_name")
	   tab.person_name = person_name;
	   tab.is_summary =  res[i]["is_summary"];
	   tab.update_logo =  res[i]["update_logo"];
	   tab.subject_id =  res[i]["subject_id"];
	   res_tab[i]=tab
	 end
	
end
responseObj.list= res_tab;
responseObj.totalPage = totalPage;
responseObj.totalRow = totalRow;
responseObj.pageNumber =pageNumber;
responseObj.pageSize =pageSize;
-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)

ngx.say(responseJson);	
