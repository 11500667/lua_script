#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有person_id参数！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有identity_id参数！\"}")
    return
end

--参数stage_id
local stage_id = tostring(ngx.var.arg_stage_id)
--判断是否有stage_id参数
if stage_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有stage_id参数！\"}")
    return
end

--参数subject_id
local subject_id = tostring(ngx.var.arg_subject_id)
--判断是否有subject_id参数 
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有subject_id参数！\"}")
    return
end

--IP地址
local ip_addr = tostring(ngx.var.remote_addr)

--当前时间
local ctime = tostring(os.date("%Y-%m-%d %H:%M:%S"))

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local res = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao","shi","qu","bm","sheng")

local v_bureau_id = res[1]
local v_city_id = res[2]
local v_district_id = res[3]
local v_org_id = res[4]
local v_province_id = res[5]
local v_stage_id = stage_id
local v_subject_id = subject_id

local str = "{\"action\":\"sp_log_subject_insert\",\"need_newcache\":\"0\",\"paras\":{\"v_bureau_id\":\""..v_bureau_id.."\",\"v_city_id\":\""..v_city_id.."\",\"v_district_id\":\""..v_district_id.."\",\"v_identity_id\":\""..cookie_identity_id.."\",\"v_ip_addr\":\""..ip_addr.."\",\"v_oper_time\":\""..ctime.."\",\"v_org_id\":\""..v_org_id.."\",\"v_person_id\":\""..cookie_person_id.."\",\"v_province_id\":\""..v_province_id.."\",\"v_stage_id\":\""..v_stage_id.."\",\"v_subject_id\":\""..v_subject_id.."\"}}"

cache:lpush("async_write_list",str)
