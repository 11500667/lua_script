#ngx.header.content_type = "text/plain;charset=utf-8"
local subject_id = tostring(ngx.var.arg_subject_id)
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)
--判断是否传了科目参数
if subject_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
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

local res_group,err = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id)
if not res_group then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

cache:init_pipeline()
for i=1,#res_group do
    cache:smembers("version_"..res_group[i].."_"..subject_id)
end
local res_version,err = cache:commit_pipeline()
if not res_version then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local l_count = 0
local version = "{\"success\":\"true\",\"version_list\":["
for i=1,#res_version do
    for j=1,#res_version[i] do
	l_count = 1
	version = version..res_version[i][j]..","	
    end
end
if l_count==0 then
    ngx.say("{\"success\":false,\"info\":\"当前科目下没有相关版本信息！\"}")
else
    version = string.sub(version,0,#version-1).."]}"
    ngx.say(version)
end
