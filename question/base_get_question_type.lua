#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_background_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_background_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_identity_id参数错误！\"}")
    return
end

--subject_id参数
local subject_id = tostring(ngx.var.arg_subject_id)
--判断是否有subject_id参数
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
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

local str_result=""

local qt_id_list = cache:smembers("qt_id_list_"..subject_id)
if #qt_id_list~=0 then
    for i=1,#qt_id_list do
        local qt_info = cache:hmget("qt_list_"..subject_id.."_"..qt_id_list[i],"qt_id","qt_name","qt_type","sort_id")
        str_result = str_result.."{\"qt_id\":\""..qt_info[1].."\",\"qt_name\":\""..qt_info[2].."\",\"qt_type\":\""..qt_info[3].."\",\"sort_id\":\""..qt_info[4].."\"},"
    end
end

str_result = string.sub(str_result,0,#str_result-1)

ngx.say("{\"success\":true,\"qt_list\":["..str_result.."]}")
