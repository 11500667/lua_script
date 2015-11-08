--[[
删除资源、试卷、备课、微课时同时删除发布关系表的数据
@Author feiliming
@Date   2015-1-5
]]
local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local redislib = require "resty.redis"

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local person_id = args["person_id"]
local identity_id = args["identity_id"]
local obj_type = args["obj_type"]
local obj_id_int = args["obj_id_int"]
if not obj_type or len(obj_type) == 0 
	or not obj_id_int or len(obj_id_int) == 0 
	or not person_id or len(person_id) == 0
	or not identity_id or len(identity_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--连接redis服务器
local redis = redislib:new()
local ok, err = redis:connect(v_redis_ip,v_redis_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--mysql
local mysql, err = mysqllib:new()
if not mysql then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local ok, err = mysql:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--ts
local n = ngx.now();
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts = ts..string.rep("0",19-string.len(ts));

--select
local ssql = "SELECT id from t_base_publish "..
	"WHERE person_id = "..quote(person_id).." "..
	"AND identity_id = "..quote(identity_id).." "..
	"AND obj_type = "..quote(obj_type).." "..
	"AND obj_id_int = "..quote(obj_id_int).." "..
	"AND b_delete = 0"
local result = mysql:query(ssql)
if result and #result > 0 then
	--update
	local usql = "UPDATE t_base_publish SET b_delete = 1, update_ts = "..quote(ts).." "..
	"WHERE person_id = "..quote(person_id)..
	" AND identity_id = "..quote(identity_id)..
	" AND obj_type = "..quote(obj_type)..
	" AND obj_id_int = "..quote(obj_id_int)
	local ok, err = mysql:query(usql)
	if ok then
		for i=1,#result do
			redis:del("publish_"..result[i].id)
		end
	end
end

say("{\"success\":true,\"info\":\"删除成功！\"}")

--放回连接池
redis:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)