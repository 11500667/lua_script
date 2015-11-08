local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--学段ID
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int = args["resource_id_int"]

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

local review_res = mysql_db:query("SELECT person_name,create_time,review_content,review_score FROM t_base_review WHERE target_type = 1 AND target_id = "..resource_id_int.." ORDER BY create_time DESC")

local review_tab = {}
for i=1,#review_res do
	local review_info = {}
	review_info["person_name"] = review_res[i]["person_name"]
	review_info["create_time"] = review_res[i]["create_time"]
	review_info["review_content"] = review_res[i]["review_content"]
	review_info["review_score"] = review_res[i]["review_score"]
	review_tab[i] = review_info
end

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local cjson = require "cjson"
local result = {} 
result["list"] = review_tab
result["success"] = true

cjson.encode_empty_table_as_object(false);

ngx.print(cjson.encode(result))
