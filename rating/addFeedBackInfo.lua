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

--反馈内容
if args["feedback_content"] == nil or args["feedback_content"] == "" then
    ngx.say("{\"success\":false,\"info\":\"feedback_content参数错误！\"}")
    return
end
local feedback_content = args["feedback_content"]

--人员ID
local person_id = tostring(ngx.var.cookie_person_id)

--人员姓名
local person_name = tostring(ngx.var.cookie_person_name)

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

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local bureau_id = redis_db:hget("person_"..person_id.."_5","xiao")

local bureau_name = redis_db:hget("t_base_organization_"..bureau_id,"org_name")

local feedback_date = tostring(ngx.today())

mysql_db:query("INSERT INTO t_rating_feedback (rating_id,person_id,person_name,bureau_id,bureau_name,feedback_date,feedback_content) VALUES ('"..rating_id.."','"..person_id.."','"..person_name.."','"..bureau_id.."','"..bureau_name.."','"..feedback_date.."','"..feedback_content.."')")

mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)

local result = {} 
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))












