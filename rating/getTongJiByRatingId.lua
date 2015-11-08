local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
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

local cjson = require "cjson"

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end


--评比名称和开始、结束时间
local rating_res = mysql_db:query("SELECT rating_title,start_date,end_date,rating_sub_title FROM t_rating_info WHERE b_use = 1 AND id = "..rating_id..";")
local rating_title = rating_res[1]["rating_title"]
local rating_sub_title = rating_res[1]["rating_sub_title"]
local start_date = string.sub(rating_res[1]["start_date"],0,10)
local end_date = string.sub(rating_res[1]["end_date"],0,10)

--参赛人数
local csrs_res = mysql_db:query("SELECT COUNT(DISTINCT person_id) AS count FROM t_rating_resource WHERE resource_status = 3 AND rating_id = "..rating_id..w_type)
local csrs_count = csrs_res[1]["count"]

--已有作品数
local yyzp_res = mysql_db:query("SELECT COUNT(1) AS count FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status = 3"..w_type)
local yyzp_count = yyzp_res[1]["count"]

--已获投票数
local yhtp_res = mysql_db:query("SELECT IFNULL(SUM(vote_count),0) AS count FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status = 3"..w_type)
local yhtp_count = yhtp_res[1]["count"]

--参赛学校数
local csxx_res = mysql_db:query("SELECT COUNT(DISTINCT bureau_id) AS count FROM t_rating_resource WHERE resource_status = 3 AND  rating_id = "..rating_id..w_type)
local csxx_count = csxx_res[1]["count"]

local result = {} 
result["rating_title"] = rating_title
result["rating_sub_title"] = rating_sub_title
result["start_date"] = start_date
result["end_date"] = end_date
result["csrs_count"] = csrs_count
result["yyzp_count"] = yyzp_count
result["yhtp_count"] = yhtp_count
result["csxx_count"] = csxx_count
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


