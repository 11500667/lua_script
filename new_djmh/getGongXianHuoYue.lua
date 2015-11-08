local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
    return
end
local bureau_id = args["bureau_id"]

--显示多少条
if args["show_size"] == nil or args["show_size"] == "" then
    ngx.say("{\"success\":false,\"info\":\"show_size参数错误！\"}")
    return
end
local show_size = args["show_size"]

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local djmh_gxhy_ts = redis_db:get("djmh_gxhy_ts_"..bureau_id)
local generate_gxhy_ts = redis_db:get("generate_gxhy_ts_"..bureau_id)

if generate_gxhy_ts == ngx.null or djmh_gxhy_ts ~= generate_gxhy_ts then

	local  update_ts = math.random(1000000)
	
	redis_db:set("djmh_gxhy_ts_"..bureau_id,update_ts)
	redis_db:set("generate_gxhy_ts_"..bureau_id,update_ts)

	local gxOrg,gxUser,hyOgr,hyUser = ngx.location.capture_multi({
		{"/dsideal_yy/new_djmh/getGongXianOrg?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
		{"/dsideal_yy/new_djmh/getGongXianUser?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
		{"/dsideal_yy/new_djmh/getHuoYueOrg?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
		{"/dsideal_yy/new_djmh/getHuoYueUser?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)}
	})

	local result = {}
	result["success"] = true
	result["gxOrg"] = cjson.decode(gxOrg.body).list
	result["gxUser"] = cjson.decode(gxUser.body).list
	result["hyOgr"] = cjson.decode(hyOgr.body).list
	result["hyUser"] = cjson.decode(hyUser.body).list
	
	cjson.encode_empty_table_as_object(false)
	redis_db:set("djmh_gxhy_"..bureau_id,cjson.encode(result))

end

local result = redis_db:get("djmh_gxhy_"..bureau_id)
redis_db:set_keepalive(0,v_pool_size)

ngx.print(result)