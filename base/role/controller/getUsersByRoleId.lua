--根据角色ID和身份ID获取用户信息 by huyue 2015-08-03
--1.获得参数方法
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
-- 获取数据库连接
local mysql = require "resty.mysql";
local mysql_db, err = mysql : new();
if not mysql_db then
  ngx.log(ngx.ERR, err);
  return;
end

mysql_db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = mysql_db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }
 
  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local query_condition = " where 1=1 ";


local role_id = args["role_id"];
local identity_id =  args["identity_id"]
if args["role_id"] == nil or args["role_id"] == "" then

  else 
	query_condition= query_condition.." and t1.role_id ="..role_id;
	if identity_id == nil or identity_id=="" then
		local query_identity_sql = "select identity_id from t_sys_role where role_id="..role_id;
		ngx.log(ngx.ERR,"hy_log-->根据角色查询身份"..query_identity_sql);
		local query_identity_res=mysql_db:query(query_identity_sql);

		if  query_identity_res and query_identity_res[1] then
			identity_id=tonumber(query_identity_res[1]["identity_id"]);
		end
	end
	
end

if args["person_name"] == nil or args["person_name"] == "" then
 
 else
	if identity_id==6 then
	
		query_condition= query_condition.." AND t2.student_name like '%"..args["person_name"].."%'";
	
	else
		query_condition= query_condition.." AND t2.person_name like '%"..args["person_name"].."%'";
	end

end

local query_person_sql,query_count_sql;
if identity_id==6 then
	--查询学生表
	query_person_sql="select distinct t2.student_id as person_id,t2.stu_num as person_num,t2.student_name as person_name,t4.org_id,t4.org_name as person_name,5 as identity_id from T_SYS_PERSON_ROLE t1  join t_base_student t2 on t1.person_id=t2.student_id join t_base_class t3 on t2.class_id =t3.class_id join t_base_organization t4 on t3.org_id=t4.org_id "..query_condition.." order by person_name LIMIT "..offset..","..limit; 	
	query_count_sql="select count(distinct t2.student_id) as count from T_SYS_PERSON_ROLE t1  join t_base_student t2 on t1.person_id=t2.student_id join t_base_class t3 on t2.class_id =t3.class_id join t_base_organization t4 on t3.org_id=t4.org_id "..query_condition;	
else
	query_person_sql="select distinct t2.person_id,t2.person_name,t2.person_num,t2.org_id,t3.org_name,t2.identity_id from T_SYS_PERSON_ROLE t1  join t_base_person t2 on t1.person_id=t2.person_id left join t_base_organization t3 on t2.org_id=t3.org_id  "..query_condition.." order by  person_name LIMIT "..offset..","..limit; 	
	query_count_sql="select count(distinct t2.person_id) as count from T_SYS_PERSON_ROLE t1  join t_base_person t2 on t1.person_id=t2.person_id left join t_base_organization t3 on t2.org_id=t3.org_id  "..query_condition; 	

end
ngx.log(ngx.ERR,"hy_log-->根据角色查询人的信息"..query_person_sql);
ngx.log(ngx.ERR,"hy_log-->根据角色查询人的信息"..query_count_sql);
local query_person_res=mysql_db:query(query_person_sql);
local person_tab={};
local result = {} 
if not query_person_res then
	
	result["table_List"] = {}
	result["success"] = true
	cjson.encode_empty_table_as_object(false);
	ngx.print(cjson.encode(result))
	return;
end

for i=1,#query_person_res do
	local person_res={};
	local person_id = query_person_res[i]["person_id"];
	person_res["PERSON_ID"]=person_id;
	person_res["PERSON_NAME"]=query_person_res[i]["person_name"];
	person_res["ORG_ID"]=query_person_res[i]["org_id"];
	person_res["ORG_NAME"]=query_person_res[i]["org_name"];
	person_res["PERSON_NUM"]=query_person_res[i]["person_num"];
	person_res["IDENTITY_ID"]=query_person_res[i]["identity_id"];
	local query_roleorg_sql="select group_concat(distinct t1.org_id) as role_org_id,group_concat(t2.org_name)as role_org_name from t_sys_person_role t1  join t_base_organization t2 on t1.org_id=t2.org_id  where t1.person_id="..person_id.." and t1.role_id="..role_id;
	ngx.log(ngx.ERR,"hy_log-->查询角色所在组织"..query_roleorg_sql);
	local query_roleorg_sql_res=mysql_db:query(query_roleorg_sql);
	if query_roleorg_sql_res and query_roleorg_sql_res[1] then 
		person_res["ROLE_ORG_ID"]=query_roleorg_sql_res[1]["role_org_id"];
		person_res["ROLE_ORG_NAME"]=query_roleorg_sql_res[1]["role_org_name"];
	else
		person_res["ROLE_ORG_ID"]="";
		person_res["ROLE_ORG_NAME"]="";
	end
	
	person_tab[i]=person_res;
end

local res_count = mysql_db:query(query_count_sql);
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)



--放回连接池
mysql_db:set_keepalive(0,v_pool_size)


result["table_List"] = person_tab
result["success"] = true
result["totalRow"] = tonumber(totalRow)
result["totalPage"] = tonumber(totalPage)
result["pageNumber"] = tonumber(pageNumber)
result["pageSize"] = tonumber(pageSize)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
