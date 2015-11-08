#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-08
#描述：获得该学校所有的人员
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

--传参数
if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end
local school_id  = tostring(args["school_id"]);

if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize  = tostring(args["pageSize"]);

if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber  = tostring(args["pageNumber"]);
-- 0 全部 1 已评分 2 未评分
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["check_id"] == nil or args["check_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_id参数错误！\"}")
    return
end
local check_id  = tostring(args["check_id"]);


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

local sql_person_list_count = "SELECT COUNT(1) as count FROM t_base_person AS t1 LEFT JOIN t_resource_check_person_score AS t3 ON t1.person_id = t3.person_id and t1.identity_id = t3.identity_id  and t1.identity_id = 5 and t3.check_id ="..check_id.."  and t3.subject_id="..subject_id.."  WHERE BUREAU_ID = "..school_id.." and t1.identity_id = 5";

--拼接sql语句
local sql_person_list = "";

local offset = pageSize*pageNumber-pageSize;
local limit = pageSize;


local sql_limit = " limit "..offset..","..limit;
if subject_id ~= "0" then
   sql_person_list = "SELECT  t1.identity_id,t1.person_id,t1.person_name,IFNULL(t3.person_id,0) as is_scored,IFNULL(t3.person_comments,'') as person_comments,IFNULL(t3.person_socre,0) as person_socre,(select COUNT(1) from t_resource_sendcheck t2 where t2.person_id=t1.PERSON_ID AND t2.check_id = "..check_id.." and t2.subject_id = "..subject_id..") as count FROM t_base_person AS t1 LEFT JOIN t_resource_check_person_score AS t3 ON t1.person_id = t3.person_id and t1.identity_id = t3.identity_id and t1.identity_id = 5 and t3.check_id ="..check_id.." and t3.subject_id="..subject_id.."  WHERE BUREAU_ID = "..school_id.." and t1.identity_id = 5";
   if type_id == "0" then
       sql_person_list_count = sql_person_list_count;
       sql_person_list = sql_person_list.."  order by person_socre desc "..sql_limit;
   elseif type_id =="1" then

	  sql_person_list_count = sql_person_list_count.." and t3.person_id <> 0" ;
	  sql_person_list = sql_person_list.." and t3.person_id <> 0   order by person_socre desc "..sql_limit;
   else
	    sql_person_list_count = sql_person_list_count.." and t3.person_id is null ";
	  sql_person_list = sql_person_list.." and t3.person_id is null   order by person_socre desc "..sql_limit;
  end

else
   sql_person_list = "SELECT  t1.identity_id,t1.person_id,t1.person_name,IFNULL(t3.person_id,0) as is_scored,IFNULL(t3.person_comments,'') as person_comments,IFNULL(t3.person_socre,0) as person_socre,(select COUNT(1) from t_resource_sendcheck t2 where t2.person_id=t1.PERSON_ID AND t2.check_id = "..check_id.." ) as count FROM t_base_person AS t1 LEFT JOIN t_resource_check_person_score AS t3 ON t1.person_id = t3.person_id and t1.identity_id = t3.identity_id and t1.identity_id = 5 and t3.check_id ="..check_id.." WHERE BUREAU_ID = "..school_id.." and t1.identity_id = 5 ";
   if type_id == "0" then
       sql_person_list = sql_person_list.." order by person_socre desc " ..sql_limit;
   elseif type_id =="1" then
	   sql_person_list_count = sql_person_list_count.." and t3.person_id <> 0 ";
	   sql_person_list = sql_person_list.." and t3.person_id <> 0   order by person_socre desc "..sql_limit;
   else
       sql_person_list_count = sql_person_list_count.." and t3.person_id is null  ";
	  sql_person_list = sql_person_list.." and t3.person_id is null  order by person_socre desc "..sql_limit;
  end
  
end
local count_result = db:query(sql_person_list_count);
local count = count_result[1]["count"];
local totalPage = math.floor((count+pageSize-1)/pageSize);

local result_personlist, err, errno, sqlstate = db:query(sql_person_list)
	if not result_personlist then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};
local person_list = {};
for i=1,#result_personlist do
   local tab={};
   tab.person_id = result_personlist[i]["person_id"];
   tab.person_name = result_personlist[i]["person_name"];
   tab.is_scored = result_personlist[i]["is_scored"];
   tab.person_socre = result_personlist[i]["person_socre"];
   tab.count = result_personlist[i]["count"];
   tab.person_comments = result_personlist[i]["person_comments"];
   tab.identity_id = result_personlist[i]["identity_id"];
   
   person_list[i] = tab;
end
resultJson.success = true;
resultJson.totalRow = count;
resultJson.pageSize = pageSize;
resultJson.totalPage = totalPage;
resultJson.pageNumber = pageNumber;
resultJson.person_list = person_list;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);












