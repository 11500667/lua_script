--根据身份ID获取角色 by huyue 2015-07-31
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
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end


local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local query_condition = " where B_USE=1 ";
if args["identity_id"] == nil or args["identity_id"] == "" then

else

	query_condition=query_condition.." and identity_id="..tonumber(args["identity_id"]);
end

if args["role_name"] == nil or args["role_name"] == "" then

else

	query_condition=query_condition.." and role_name like '%"..args["role_name"].."%'";
end


local query_role_sql="select role_id,role_name,identity_id,role_code,business_system_source from t_sys_role"..query_condition.." ORDER BY ROLE_ID DESC LIMIT "..offset..","..limit;

ngx.log(ngx.ERR,"role_log----------->"..query_role_sql);
local query_role_res = mysql_db:query(query_role_sql);

local role_tab={};
for i=1,#query_role_res do
	local role_res={};
	role_res["ROLE_ID"]=query_role_res[i]["role_id"];
	role_res["ROLE_NAME"]=query_role_res[i]["role_name"];
	role_res["IDENTITY_ID"]=query_role_res[i]["identity_id"];
	role_res["ROLE_CODE"]=query_role_res[i]["role_code"];
	role_res["BUSINESS_SYSTEM_SOURCE"]=query_role_res[i]["business_system_source"];
	role_tab[i]=role_res;
end


local res_count = mysql_db:query("SELECT COUNT(1) AS COUNT from  t_sys_role"..query_condition);
local totalRow = res_count[1]["COUNT"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["table_List"] = role_tab
result["success"] = true
result["totalRow"] = tonumber(totalRow)
result["totalPage"] = tonumber(totalPage)
result["pageNumber"] = tonumber(pageNumber)
result["pageSize"] = tonumber(pageSize)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
