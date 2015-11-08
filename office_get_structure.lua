#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id的cookie信息参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id的cookie信息参数错误！\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--subject_id
local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local structure_info = cache:get("zs_"..subject_id)

if structure_info == ngx.null then
      -- ngx.say("{\"success\":false,\"info\":\"没有找到该版本信息！\"}")
      ngx.say("{\"success\":\"true\",\"structure_info\":[]}")
      return
end

local structure_json = "{\"success\":\"true\",\"structure_info\":"..structure_info.."}"
ngx.say(structure_json)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
