local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--人员ID
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

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
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local person_info = redis_db:hmget("person_"..person_id.."_5","shi","qu","xiao")

if person_info[1] ~= ngx.null then
	local person_shi = person_info[1]
	local person_qu = person_info[2]
	local person_xiao = person_info[3]
	
	
	local uuid =  require "resty.uuid";
	
	redis_db:set("djmh_gxhy_ts_"..person_shi,uuid.new())
	redis_db:set("djmh_gxhy_ts_"..person_qu,uuid.new())
	redis_db:set("djmh_gxhy_ts_"..person_xiao,uuid.new())

	--记录用户活跃度
	ssdb_db:zincr("huoyue_user_"..person_shi,person_id)
	ssdb_db:zincr("huoyue_user_"..person_qu,person_id)
	ssdb_db:zincr("huoyue_user_"..person_xiao,person_id)

	--记录机构活跃度
	ssdb_db:zincr("huoyue_org_"..person_shi,person_xiao)
	ssdb_db:zincr("huoyue_org_"..person_qu,person_xiao)
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
redis_db:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
ngx.print(cjson.encode(result))
