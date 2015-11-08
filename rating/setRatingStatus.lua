local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评比名称
if args["rating_id"] == nil or args["rating_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
	return
end
local rating_id = args["rating_id"]

--评比状态
if args["rating_status"] == nil or args["rating_status"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"rating_status参数错误！\"}")
	return
end
local rating_status = args["rating_status"]

--评比活动的单位id
local org_id = tostring(ngx.var.cookie_background_bureau_id)
if org_id=="nil" then
	org_id=0
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

if rating_status == "2" or rating_status == "3" or rating_status == "5" then
	--校验是否有已开始的评比
	local start_count = mysql_db:query("SELECT count(1) AS count FROM t_rating_info WHERE id <> "..rating_id.." AND org_id = "..org_id.." AND rating_status IN (2,3,5) AND b_use = 1 and rating_type = (select rating_type from t_rating_info where id='"..rating_id.."')")
	ngx.log(ngx.ERR,"SELECT count(1) AS count FROM t_rating_info WHERE id <> "..rating_id.." AND org_id = "..org_id.." AND rating_status IN (2,3,5) AND b_use = 1 and rating_type = (select rating_type from t_rating_info where id='"..rating_id.."')")
	if tostring(start_count[1]["count"]) ~= "0" then
		result["success"] = false
		result["info"] = "还有未结束的评比活动，不能修改该状态！"
	else
		mysql_db:query("UPDATE  t_rating_info SET rating_status = "..rating_status.." WHERE id="..rating_id)
		mysql_db:query("UPDATE  t_rating_resource SET rating_status = "..rating_status.." WHERE rating_id="..rating_id)
		result["success"] = true
	end
else
	mysql_db:query("UPDATE  t_rating_info SET rating_status = "..rating_status.." WHERE id="..rating_id)
	mysql_db:query("UPDATE  t_rating_resource SET rating_status = "..rating_status.." WHERE rating_id="..rating_id)
	result["success"] = true
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))