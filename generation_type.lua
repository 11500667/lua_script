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
--资源的id
local info_id = tostring(args["id"])
if info_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"info_id参数错误！\"}")
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据info的id获得对应的resource_id_int
local resource_id_int = ssdb_db:multi_hget("resource_"..info_id,"resource_id_int")
if resource_id_int[2] == ngx.null then
   ngx.say("{\"success\":\"false\",\"info\":\"没有找到该资源信息\"}")
return
end
--根据resource_id_int获得对应的生成类型信息

local generation_type = cache:lrange("generationtype_"..resource_id_int[2],0,-1)
local str = ""
if #generation_type ~= 0 then
  for j =1,#generation_type do
    str = str..generation_type[j]
  end
else
ngx.say("{\"success\":\"false\",\"info\":\"该资源没有对应的生成类型\"}")
return
end

  -- str = string.sub(str,0,#str-1)
local json = "{\"success\":\"true\",\"generation_type\":\""..str.."\"}"

cache:set_keepalive(0,v_pool_size)

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say(json)
