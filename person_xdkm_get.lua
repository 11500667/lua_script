#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == nil or cookie_person_id == "" then
    ngx.say("{\"success\":false,\"info\":\"notlogin\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == nil or cookie_identity_id == "" then
    ngx.say("{\"success\":false,\"info\":\"notlogin\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == nil or cookie_token == "" then
    ngx.say("{\"success\":false,\"info\":\"notlogin\"}")
    return
end

-- ngx.log(ngx.ERR, "===>===>===>===> 获取用户的学段科目 <===<===<===<===");
--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获取redis中该用户的token
local redis_token,err = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"token")
if not redis_token then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--验证cookie中的token和redis中存的token是否相同
if redis_token ~= cookie_token then
    ngx.say("{\"success\":\"false\",\"info\":\"错误的验证信息！\"}")
    return
end

local xdkm_list,err = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"stage_id","subject_id","stage_name","subject_name","scheme_id","structure_id","is_root","pid_str")

--ngx.say(xdkm_list[8])

if not xdkm_list then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

if tostring(xdkm_list[1])=="userdata: NULL" then
    ngx.say("{\"success\":true,\"xdkm_list\":[]}")
    return
end

local str = "\"xdkm_list\":[\"##\",\"##\",\"##\",\"##\",\"##\",\"##\",\"##\",\"##\"]"

for i=1,#xdkm_list do
    str = string.gsub(str,"##",xdkm_list[i],1)
end
-- ngx.log(ngx.ERR, "===> 当前用户的保存的学段科目-> xdkm_list ===> ", str);
ngx.say("{\"success\":\"true\","..str.."}")

