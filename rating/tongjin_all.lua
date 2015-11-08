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

local rating_type
if args["rating_type"] == nil or args["rating_type"] == "" then
  rating_type = 1
else
  rating_type = args["rating_type"]
end

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end

--参赛人数
local csrs_res = mysql_db:query("SELECT COUNT(DISTINCT person_id) AS count FROM t_rating_resource WHERE rating_id in (select id from t_rating_info where rating_type="..rating_type..w_type..") and  resource_status = 3;")
local csrs_count = csrs_res[1]["count"]

--已有作品数
local yyzp_res = mysql_db:query("SELECT COUNT(1) AS count FROM t_rating_resource WHERE rating_id in (select id from t_rating_info where rating_type="..rating_type..w_type..") and  resource_status = 3;")
local yyzp_count = yyzp_res[1]["count"]

--已获投票数
local yhtp_res = mysql_db:query("SELECT IFNULL(SUM(vote_count),0) AS count FROM t_rating_resource WHERE rating_id in (select id from t_rating_info where rating_type="..rating_type..w_type..") and  resource_status = 3;")
local yhtp_count = yhtp_res[1]["count"]

local result = {} 
result["csrs_count"] = csrs_count
result["yyzp_count"] = yyzp_count
result["yhtp_count"] = yhtp_count
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


