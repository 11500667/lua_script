local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--id
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"id参数错误！\"}")
    return
end
local id = args["id"]

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

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据ID获取rating_id
local rating_id = mysql_db:query("SELECT rating_id FROM t_rating_resource WHERE id = "..id)

--获取数据库中限制的投票数
local limitVoteCount = mysql_db:query("SELECT vote_count,rating_type FROM t_rating_info WHERE id = "..rating_id[1]["rating_id"])
local rating_type = limitVoteCount[1]["rating_type"]
local resource_res = mysql_db:query("SELECT resource_info_id,vote_count,person_name,bureau_name,ts,resource_memo,person_id,remark FROM t_rating_resource WHERE id = "..id)

local resource_info_id = resource_res[1]["resource_info_id"]
local vote_count = resource_res[1]["vote_count"]
local person_name = resource_res[1]["person_name"]
local bureau_name = resource_res[1]["bureau_name"]
local person_id = resource_res[1]["person_id"]
local remark = resource_res[1]["remark"]

 local qu_id = redis_db:hget("person_"..person_id.."_5","qu")
  local shi_id = redis_db:hget("person_"..person_id.."_5","shi")

local ts = resource_res[1]["ts"]
local create_time = string.sub(ts,0,4).."-"..string.sub(ts,5,6).."-"..string.sub(ts,7,8)
local resource_memo = resource_res[1]["resource_memo"]
    if rating_type == 1 then
--local resource_title = redis_db:hget("resource_"..resource_info_id,"resource_title")
local resource_title = ssdb:multi_hget("resource_"..resource_info_id,"resource_title")
result["resource_title"] = resource_title[2]
end

local result = {}

result["success"] = true
result["vote_count"] = vote_count
result["person_name"] = person_name
result["bureau_name"] = bureau_name
result["person_id"] = person_id
result["resource_memo"] = resource_memo
result["upload_date"] = create_time
result["shi_id"] = shi_id
result["qu_id"] = qu_id
result["remark"] = remark

result["total_vote_count"] = limitVoteCount[1]["vote_count"]

mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))









