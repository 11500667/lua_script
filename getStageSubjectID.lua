local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
--[[
--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
]]

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--xdkm_ch
local xdkm = tostring(ngx.var.arg_xdkm_ch)
--判断是否有xdkm_ch参数
if xdkm == "nil" then
    ngx.say("{\"success\":false,\"info\":\"xdkm_ch参数错误！\"}")
    return
end

xdkm = ngx.decode_base64(xdkm)
local stage_name = string.sub(xdkm,1,6)
local subject_name = string.sub(xdkm,7,#xdkm)
local stage_id = cache:hmget("stage_name_key",stage_name)
local subject_id = cahce:hmget("subject_name_key_"..stage_id,subject_name)

ngx.say(stage_id)
ngx.say(subject_id)
