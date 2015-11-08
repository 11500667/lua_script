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

local old_score = 0
local old_score_res = mysql_db:query("SELECT score FROM t_rating_expert_resource WHERE rating_id = "..rating_id.." AND resource_info_id = "..resource_info_id.." AND person_id = "..person_id)
if old_score_res[1] ~= nil then
	old_score = tonumber(old_score_res[1]["score"])
end

mysql_db:query("UPDATE t_rating_resource SET SCORCE = SCORCE - "..old_score.." + "..score.." WHERE rating_id = "..rating_id.." AND resource_info_id = "..resource_info_id)

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))















