local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

local rating_type=""
if args["rating_type"] ~= nil and args["rating_type"] ~= "" then
  rating_type = args["rating_type"]
else
  rating_type = 1
end

--评比活动的单位id
local org_id = ""
if args["district_id"] ~= nil and args["district_id"] ~= "" then
	org_id = args["district_id"]
else
	org_id = tostring(ngx.var.cookie_background_bureau_id)
end


local offset = pageSize*pageNumber-pageSize
local limit = pageSize


local sql=""
local query_sql=""

local person_id = tostring(ngx.var.cookie_background_person_id)
if person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"请登录后重试！\"}")
    return
end

--评比活动的单位id
if tonumber(rating_type) ~= 1 then
	sql="SELECT count(1) as count FROM t_rating_info WHERE rating_type !=1  AND b_use=1;"
	query_sql="SELECT id,rating_title,start_date,end_date,rating_status,rating_range,rating_type FROM t_rating_info WHERE rating_type !=1  AND b_use=1 and person_id like '%"..person_id.."%' ORDER BY ts DESC LIMIT "..offset..","..limit..";"
else 
	sql="SELECT count(1) as count FROM t_rating_info WHERE  org_id="..org_id.." AND b_use=1;"
	query_sql="SELECT id,rating_title,start_date,end_date,rating_status,rating_range FROM t_rating_info WHERE  rating_type="..rating_type.." and org_id="..org_id.." AND b_use=1 ORDER BY ts DESC LIMIT "..offset..","..limit..";"
end

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

local res_count = mysql_db:query(sql)
ngx.log(ngx.ERR,sql)
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
local res = mysql_db:query(query_sql)
ngx.log(ngx.ERR,query_sql)

local rating_tab = {}
for i=1,#res do
	local rating_res = {}
	rating_res["id"] = res[i]["id"]
	rating_res["rating_title"] = res[i]["rating_title"]
	rating_res["start_date"] = string.sub(res[i]["start_date"],0,10)
	rating_res["end_date"] = string.sub(res[i]["end_date"],0,10)
	rating_res["rating_status"] = res[i]["rating_status"]
	rating_res["rating_range"] = res[i]["rating_range"]
	rating_res["rating_type"] = res[i]["rating_type"]
	rating_tab[i] = rating_res
end

local result = {} 
result["list"] = rating_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))



