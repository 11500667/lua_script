--[[
前台接口Lua，判断当前登录用户是否有发布微课到联盟权限
@Author feiliming
@Date   2015-2-4
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local redislib = require "resty.redis"
local ssdblib = require "resty.ssdb"

--get args
local person_id = ngx.var.arg_person_id
local identity_id = ngx.var.arg_identity_id

if not identity_id or len(identity_id) == 0 
    or not person_id or len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--redis
local redis = redislib:new()
local ok, err = redis:connect(v_redis_ip,v_redis_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local school_id = redis:hget("person_"..person_id.."_"..identity_id, "xiao")

if not school_id or school_id == ngx.null then
	local rr = {}
	rr.success = true
	rr.b = 0
	say(cjson.encode(rr))
	redis:set_keepalive(0,v_pool_size)
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

local sql = "SELECT league_id FROM t_wklm_school t WHERE school_id = "..quote(school_id)
local list = mysql:query(sql)
if not list or #list == 0 then
	--联盟中未找到学校
	local rr = {}
	rr.success = true
	rr.b = 0
	say(cjson.encode(rr))
	redis:set_keepalive(0,v_pool_size)
	mysql:set_keepalive(0,v_pool_size)
    return
end

--
local rr = {}
rr.success = true
rr.b = 1
say(cjson.encode(rr))
redis:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)
