local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源的INFO_ID
if args["resource_info_id"] == nil or args["resource_info_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_info_id参数错误！\"}")
    return
end
local resource_info_id = args["resource_info_id"]

--资源的得分
if args["score"] == nil or args["score"] == "" then
    ngx.say("{\"success\":false,\"info\":\"score参数错误！\"}")
    return
end
local score = args["score"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--获取resource_id_int
--local resource_info = cache:hmget("resource_"..resource_info_id,"resource_id_int","scheme_id_int")
local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int","scheme_id_int")
local resource_id_int = resource_info[2]
local scheme_id_int = resource_info[4]

--获取该资源的stage_id和subject_id
local res = db:query("select stage_id,subject_id from t_resource_scheme where scheme_id="..scheme_id_int)
local stage_id = res[1]["stage_id"]
local subject_id = res[1]["subject_id"]


--向所有资源的总分增加
ssdb_db:hincr("resource_score_all","total_score",score)

--向单个资源的评分次数+1和+总分
ssdb_db:hincr("resource_score_"..resource_id_int,"total_count")
ssdb_db:hincr("resource_score_"..resource_id_int,"total_score",score)

--获取该评分资源的贝叶斯得分
local bayes_body = ngx.location.capture("/dsideal_yy/tangshan/getBayes?resource_id_int="..resource_id_int)
local bayes_score = bayes_body.body

--获取现有排序中按学段获取最小的
local least_state_info = ssdb_db:zrange("resource_sort_"..stage_id,0,1)
local least_state_resource_id_int = least_state_info[1]
local least_state_score = least_state_info[2]

--获取现有排序中按学段和学科获取最小的
local least_state_subject_info = ssdb_db:zrange("resource_sort_"..stage_id.."_"..subject_id,0,1)
local least_state_subject_resource_id_int = least_state_subject_info[1]
local least_state_subject_score = least_state_subject_info[2]

if bayes_score == nil then
    bayes_score = "0"
end
if least_state_score == nil then
    least_state_score = "0"
end
if least_state_subject_score == nil then
    least_state_subject_score = "0"
end

if tonumber(bayes_score)>tonumber(least_state_score) then	
	local exist = ssdb_db:zrank("resource_sort_"..stage_id,resource_id_int)
	if tostring(exist) == "error" then
		ssdb_db:zdel("resource_sort_"..stage_id,least_state_resource_id_int)
		ssdb_db.hdel("resource_sort_infoid_idint_"..stage_id,least_state_resource_id_int)
	end
	ssdb_db:zset("resource_sort_"..stage_id,resource_id_int,bayes_score)
	ssdb_db:hset("resource_sort_infoid_idint_"..stage_id,resource_id_int,resource_info_id)
end

if tonumber(bayes_score)>tonumber(least_state_subject_score) then
	local exist = ssdb_db:zrank("resource_sort_"..stage_id.."_"..subject_id,resource_id_int)
	if tostring(exist) == "error" then
		ssdb_db:zdel("resource_sort_"..stage_id.."_"..subject_id,least_state_subject_resource_id_int)
		ssdb_db:hdel("resource_sort_infoid_idint_"..stage_id.."_"..subject_id,least_state_subject_resource_id_int)		
	end
	ssdb_db:zset("resource_sort_"..stage_id.."_"..subject_id,resource_id_int,bayes_score)	
	ssdb_db:hset("resource_sort_infoid_idint_"..stage_id.."_"..subject_id,resource_id_int,resource_info_id)
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true}")
