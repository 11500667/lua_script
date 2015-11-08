--获取学科树 by huyue 2015-07-22
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

local edu_type = args["edu_type"];

if args["edu_type"] == nil or args["edu_type"] == "" then
	
else
  edu_type = tonumber(args["edu_type"])

end

--根据edu_type查询学段
--1、基础类型2、高等教育 3、职业教育
local stage_code;
if edu_type == 1 or edu_type == 0 then
	stage_code= "001";

elseif edu_type == 2 then 
	stage_code = "002";

elseif edu_type == 3  then
	stage_code = "003";
else

	stage_code= "";
end

local query_stage_sql = "select stage_id,stage_name from t_dm_stage where stage_code like '"..stage_code.."%' and level = 2";


ngx.log(ngx.ERR,"subject_log----------->"..query_stage_sql);

local query_stage_res = mysql_db:query(query_stage_sql);



local stage_id="";

local m=1;
local subject_tab = {}

local subject_res={};
subject_res["id"] = "0";
subject_res["name"] = "全部学科";
subject_res["pId"] = "-1"
subject_res["open"] = true;
subject_res["nocheck"] = true;
subject_res["noRemoveBtn"] = true;
subject_res["noEditBtn"] = true;
subject_res["noAddBtn"] = true;
subject_tab[m] = subject_res;
m=m+1;


for i=1,#query_stage_res do
	stage_id = stage_id..query_stage_res[i]["stage_id"]..",";
	local stage_res = {}
	stage_res["id"] = "stage"..query_stage_res[i]["stage_id"];
	stage_res["name"] = query_stage_res[i]["stage_name"];
	stage_res["pId"] = "0"
	stage_res["open"] = false;
	stage_res["nocheck"] = true;
	stage_res["noEditBtn"] = true;
	stage_res["noRemoveBtn"] = true;
	subject_tab[m] =stage_res
	m=m+1;
end

stage_id = string.sub(stage_id,0,string.len(stage_id)-1);

local query_subject_sql="select subject_id,subject_name,stage_id from t_dm_subject where stage_id in ("..stage_id..")";

ngx.log(ngx.ERR,"subject_log----------->"..query_subject_sql);
local query_subject_res= mysql_db:query(query_subject_sql);

	for j=1,#query_subject_res do
		local sub_res = {}
		sub_res["id"] = query_subject_res[j]["subject_id"]
		sub_res["name"] = query_subject_res[j]["subject_name"]
		sub_res["pId"] = "stage"..query_subject_res[j]["stage_id"]
		sub_res["open"] = false;
		sub_res["noAddBtn"] = true;
	
		subject_tab[m] = sub_res;
		m=m+1;
	end


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["table_List"] = subject_tab

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))