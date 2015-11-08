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

--显示多少条
if args["show_size"] == nil or args["show_size"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"show_size参数错误！\"}")
    return
end
local show_size = args["show_size"]

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end


local school_res = mysql_db:query("SELECT bureau_id,bureau_name,count(1) AS count FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status=3 "..w_type.." GROUP BY bureau_id ORDER BY count(1) DESC LIMIT "..show_size)

local school_tab = {}

if school_res[1] ~= nil then
	for i=1,#school_res do
		local school = {}
		
		school["bureau_id"] = school_res[i]["bureau_id"]
		school["bureau_name"] = school_res[i]["bureau_name"]
		school["count"] = school_res[i]["count"]
		
		school_tab[i] = school
	end
end

local result = {} 
result["list"] = school_tab
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


