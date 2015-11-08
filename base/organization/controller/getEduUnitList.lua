#获取教育单位列表  by huyue 2015-06-27
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

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
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

local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local org_name = args["org_name"]
local queryCondition = " 1=1 "

if org_name == nil or org_name == '' then
else
	queryCondition = queryCondition.." AND ORG_NAME like '%"..org_name.."%' ";
end

local area_id = args["area_id"]
if area_id == nil or area_id == '' then
 -- ngx.say("{\"success\":false,\"info\":\"area_id不能为空\"}")
 -- return
else
	queryCondition = queryCondition.." AND AREA_ID = "..area_id;
end

local org_type = args["org_type"]

if org_type == nil or org_type =='' then 


else

queryCondition = queryCondition.." AND ORG_TYPE in("..org_type..") ";

end

local org_id = args["org_id"]

if org_id == nil or org_id =='' then 


else

queryCondition = queryCondition.." AND  ORG_CODE like'%/_"..org_id.."/_%'  escape '/' and org_id<>"..org_id 

end


local res_count = db:query("SELECT COUNT(1) AS COUNT FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE "..queryCondition.." AND B_GROUP = 0 ORDER BY CREATE_TIME DESC");
local totalRow = res_count[1]["COUNT"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local res = db:query("SELECT T1.ORG_ID,T1.ORG_NAME,T1.JP,T2.TYPE_NAME,T1.ADDRESS,T1.CREATE_TIME,T1.AREA_ID,T1.ORG_TYPE FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE "..queryCondition.." AND B_GROUP = 0 ORDER BY CREATE_TIME DESC LIMIT "..offset..","..limit..";");

ngx.log(ngx.ERR, "hu_log->".."SELECT T1.ORG_ID,T1.ORG_NAME,T2.TYPE_NAME,T1.ADDRESS,T1.CREATE_TIME,T1.AREA_ID,T1.ORG_TYPE FROM T_BASE_ORGANIZATION T1 LEFT JOIN T_DM_EDUTYPE T2 ON T1.EDU_TYPE = T2.TYPE_ID WHERE "..queryCondition.." AND B_GROUP = 0 ORDER BY CREATE_TIME DESC LIMIT "..offset..","..limit..";")

local org_tab = {}
for i=1,#res do
	local org_res = {}
	org_res["ORG_ID"] = res[i]["ORG_ID"]
	org_res["ORG_NAME"] = res[i]["ORG_NAME"]
	org_res["TYPE_NAME"] = res[i]["TYPE_NAME"]
	org_res["ADDRESS"] = res[i]["ADDRESS"]
	org_res["CREATE_TIME"] = res[i]["CREATE_TIME"]
	org_res["AREA_ID"] = res[i]["AREA_ID"]
	org_res["ORG_TYPE"] = res[i]["ORG_TYPE"]
	org_res["JP"] = res[i]["JP"]
	
	
	org_tab[i] = org_res
end

local result = {} 
result["table_List"] = org_tab
result["totalRow"] = tonumber(totalRow)
result["totalPage"] = tonumber(totalPage)
result["pageNumber"] = tonumber(pageNumber)
result["pageSize"] = tonumber(pageSize)
result["success"] = true
db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);

ngx.print(cjson.encode(result))




