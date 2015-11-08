#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--question_id_char参数
local question_id_char = tostring(ngx.var.arg_question_id_char)
--判断是否有question_id_char参数
if question_id_char == "nil" then
    ngx.say("{\"success\":false,\"info\":\"question_id_char参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

cache:set("test","11111111111")

local str = "{\"action\":\"sp_question_usecountinc\",\"need_newcache\":\"0\",\"paras\":{\"p_question_id_char\":\""..question_id_char.."\"}}"

cache:lpush("async_write_list_first",str)

ngx.say("{\"success\":true}")
