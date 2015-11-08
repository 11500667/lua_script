local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--人员ID
local person_id = "-1"
if ngx.var.cookie_person_id ~= nil then
	person_id = tostring(ngx.var.cookie_person_id)
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

local result = {} 
result["success"] = false

--评比方式 1：投票 2：量规 3：推荐

local rating_res = mysql_db:query("SELECT rating_range FROM t_rating_info WHERE id = "..rating_id)
local rating_range = rating_res[1]["rating_range"]

result["rating_range"] = rating_range

local rating_range_name = ""
if tostring(rating_range) == "1" then
	rating_range_name = "教师投票"
elseif tostring(rating_range) == "2" then
	rating_range_name = "量规评分"
else
	rating_range_name = "专家推荐"
end

result["rating_range_name"] = rating_range_name

local expert_res = mysql_db:query("SELECT count(1) AS count FROM t_rating_expert WHERE rating_id = "..rating_id.." AND person_id = "..person_id)
ngx.log(ngx.ERR,"@@@".."SELECT count(1) AS count FROM t_rating_expert WHERE rating_id = "..rating_id.." AND person_id = "..person_id.."@@@")
local is_expert = expert_res[1]["count"]

if tostring(is_expert) ~= "0" then
	result["success"] = true
end

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))





