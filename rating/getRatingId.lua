local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--区ID
if args["district_id"] == nil or args["district_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"district_id参数错误！\"}")
    return
end
local district_id = args["district_id"]

--评比类型：1资源大赛，2微课大赛,默认资源大赛
local rating_type = ""
if args["rating_type"] == nil or args["rating_type"] == "" then
    rating_type = 1
else
	rating_type = args["rating_type"]
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

local rating_info = mysql_db:query("SELECT id,rating_title,rating_sub_title,start_date,end_date,rating_range,rating_status,houdongfujian , rating_type FROM t_rating_info WHERE ORG_ID = "..district_id.." AND RATING_STATUS IN (2,3,5) AND b_use = 1 and rating_type ="..rating_type)

local result = {} 

if rating_info[1] == nil then
	result["success"] = false
	result["info"] = "当前没有正在进行的评比活动！"
else
	result["success"] = true
	result["rating_id"] = rating_info[1]["id"]
	result["rating_title"] = rating_info[1]["rating_title"]
	result["rating_sub_title"] = rating_info[1]["rating_sub_title"]
	result["rating_range"] = rating_info[1]["rating_range"]
	result["rating_status"] = rating_info[1]["rating_status"]
	result["file_id"] = rating_info[1]["houdongfujian"]
	result["rating_type"] = rating_info[1]["rating_type"]
	result["start_date"] = string.sub(rating_info[1]["start_date"],0,10)
	result["end_date"] = string.sub(rating_info[1]["end_date"],0,10)
end

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
