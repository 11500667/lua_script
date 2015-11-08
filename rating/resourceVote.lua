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

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--人员ID
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

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local result = {} 
result["success"] = true

local identity_id = tostring(ngx.var.cookie_identity_id)
local limitVoteCount = mysql_db:query("SELECT vote_count FROM t_rating_info WHERE id = "..rating_id)
if identity_id == "6" then
	result["success"] = false
	result["info"] = "学生不允许投票！"
else
	--获取数据库中限制的投票数
	

	local voteCount = redis_db:hget("vote_"..rating_id,person_id)
	if voteCount ~= ngx.null then
		if tonumber(voteCount) > tonumber(limitVoteCount[1]["vote_count"])-1 then
			result["success"] = false
			result["info"] = "本次评比活动的票数已经用光！"
		end
	end	
end

if result["success"] == true then
	mysql_db:query("UPDATE t_rating_resource SET vote_count = vote_count+1 WHERE id = "..id)
	redis_db:hincrby("vote_"..rating_id,person_id,1)
	local nowVoteCount = redis_db:hget("vote_"..rating_id,person_id)
	local count_vote = tonumber(limitVoteCount[1]["vote_count"]) - tonumber(nowVoteCount)
	mysql_db:query("insert into t_dswk_vote set PERSON_ID="..person_id.." , RATING_RESOURCE_ID="..id.." , RATING_ID="..rating_id.."")
	result["count"] = count_vote
	mysql_db:set_keepalive(0,v_pool_size)
end

redis_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))