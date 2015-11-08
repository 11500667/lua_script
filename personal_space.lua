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

--人员id
local person_id = tostring(args["person_id"])
if person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
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

local personal_space_json = "{\"success\":\"true\",\"quota_totle\":\"##\",\"quota_used\":\"##\",\"quota_unuse\":\"##\"}"

local person_space_null= cache:hmget("person_space_"..person_id,"quota_total")

if person_space_null[1] == ngx.null then
 ngx.say("{\"success:\"false\",\"info\":\"没有找到该人员信息！\"}")
 return
end

local person_space = cache:hmget("person_space_"..person_id,"quota_total","quota_used","quota_unuse")
for j=1,#person_space do
     personal_space_json = string.gsub(personal_space_json,"##",person_space[j],1)
end 
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
ngx.say(personal_space_json)
