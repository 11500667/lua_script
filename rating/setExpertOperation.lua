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
    ngx.say("{\"success\":\"false\",\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--评比方试
if args["rating_range"] == nil or args["rating_range"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"rating_range参数错误！\"}")
    return
end
local rating_range = args["rating_range"]

--资源INFO_ID
if args["resource_info_id"] == nil or args["resource_info_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"resource_info_id参数错误！\"}")
    return
end
local resource_info_id = args["resource_info_id"]

--资源得分
if args["score"] == nil or args["score"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"score参数错误！\"}")
    return
end
local score = args["score"]

--人员ID
if ngx.var.cookie_person_id == nil then
	ngx.say("{\"success\":\"false\",\"info\":\"需要专家登录！\"}")
    return
end
local person_id = tostring(ngx.var.cookie_person_id)

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

mysql_db:query("INSERT INTO t_rating_expert_resource (rating_id,rating_range,person_id,score,resource_info_id) VALUES ('"..rating_id.."','"..rating_range.."','"..person_id.."','"..score.."','"..resource_info_id.."')")

local sql = ""
if rating_range == "2" then
	sql = "UPDATE t_rating_resource SET SCORCE = SCORCE+"..score.." WHERE rating_id = "..rating_id.." AND resource_info_id = "..resource_info_id
else
	sql = "UPDATE t_rating_resource SET expert_rec = expert_rec+1 WHERE rating_id = "..rating_id.." AND resource_info_id = "..resource_info_id
end

mysql_db:query(sql)

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))











