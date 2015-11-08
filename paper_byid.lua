#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--paper_id参数
local paper_id = tostring(ngx.var.arg_paper_id)
--判断是否有paper_id参数
if paper_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"paper_id参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local json_str = cache:hmget("paperinfo_"..paper_id,"json_content")

ngx.say(ngx.decode_base64(json_str[1]))

