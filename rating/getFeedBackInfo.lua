local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

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

local feedback_res = mysql_db:query("SELECT person_id,person_name,bureau_id,bureau_name,feedback_date,feedback_content FROM t_rating_feedback WHERE rating_id = "..rating_id)

local feedback_tab = {}

for i=1,#feedback_res do
	local feedback_info = {}
	feedback_info["person_id"] = feedback_res[i]["person_id"]
	feedback_info["person_name"] = decodeURI(feedback_res[i]["person_name"])
	feedback_info["bureau_id"] = feedback_res[i]["bureau_id"]
	feedback_info["bureau_name"] = feedback_res[i]["bureau_name"]
	feedback_info["feedback_date"] = feedback_res[i]["feedback_date"]
	feedback_info["feedback_content"] = feedback_res[i]["feedback_content"]
	feedback_tab[i] = feedback_info
end

local result = {} 
result["list"] = feedback_tab
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


