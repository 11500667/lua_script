#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil

if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
	-- ngx.log(ngx.ERR,ngx.req.get_post_args());
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

local check_status = tostring(args["check_status"]) 
local version_id = tostring(args["version_id"])
local all_version_ids = tostring(args["all_version_ids"])
local pageNumber = tostring(args["pageNumber"])
local pageSize = tostring(args["pageSize"])
local cookie_product_id = tostring(ngx.var.cookie_product_id) 



	
--判断是否有check_status参数
if check_status == nil  then
    ngx.say("{\"success\":false,\"info\":\"check_status参数错误！\"}")
    return
end
if check_status=="" then
	check_status = "4";
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

-- 判断是否有product_id参数
if cookie_product_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"product_id的cookie信息参数错误！\"}")
    return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100

local pre_sql = "SELECT STRUCTURE_ID,RESOURCE_TITLE,DATE_FORMAT(CREATE_TIME,'%Y-%m-%d %H:%i:%S') AS CREATE_TIME,CHECK_STATUS,RESOURCE_ID_INT,CHECK_MESSAGE ";
local next_sql = "";
if version_id == "0" then 
	next_sql = " FROM T_RESOURCE_BASE WHERE SOURCE_ID != 1 AND RES_TYPE=1 AND SCHEME_ID IN (" .. all_version_ids .. ")";
else
	next_sql = " FROM T_RESOURCE_BASE WHERE SOURCE_ID != 1 AND RES_TYPE=1 AND SCHEME_ID = " .. version_id ;
end  

if check_status ~= "4" then 
	next_sql = next_sql .. " AND CHECK_STATUS = ".. check_status .." ORDER BY create_time DESC";
else
	next_sql = next_sql .. " AND CHECK_STATUS !=0 ORDER BY create_time DESC";
end 
	
ngx.log(ngx.ERR,"============"..pre_sql..next_sql)

local res = db:query(pre_sql..next_sql);

local totalRow = table.getn(res);
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);

local question_list = ""
for i=1,#res do
	local structure_id = res[i]["STRUCTURE_ID"];
	local structure_code = cache:hmget("t_resource_structure_" .. structure_id, "structure_code");
	local sids = Split(structure_code[1],"_")
	local strucPath = "" 
	  for j=1,#sids do
		local strucId = sids[j];
		-- ngx.log(ngx.ERR,"=====strucId======="..strucId)
		local strucName = cache:hget("t_resource_structure_" .. structure_id, "structure_name");
		-- ngx.log(ngx.ERR,"=====strucName======="..tostring(strucName))
		strucPath = strucPath .. "->" .. strucName;
	  end
	
	if string.len(strucPath) > 2 then 
		strucPath =   string.sub(strucPath,3,string.len(strucPath))
	else 
		strucPath =  "略"
	end

	local resource_title = res[i]["RESOURCE_TITLE"];
	local create_time = res[i]["CREATE_TIME"];
	local resource_id_int = res[i]["RESOURCE_ID_INT"];
	local check_status = res[i]["CHECK_STATUS"];
	local check_message = res[i]["CHECK_MESSAGE"];
	
	question_list = question_list.."{\"RESOURCE_TITLE\":\""..resource_title.."\",\"CREATE_TIME\":\""..create_time.."\",\"RESOURCE_ID_INT\":\""..resource_id_int.."\",\"CHECK_MESSAGE\":\""..check_message.."\",\"CHECK_STATUS\":\""..check_status.."\",\"PARENT_NAME\":\""..strucPath .. "\"},"

end	

question_list = string.sub(question_list,0,#question_list-1)

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"table_List\":["..question_list.."]}")		
	