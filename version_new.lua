#ngx.header.content_type = "text/plain;charset=utf-8"
local subject_id = tostring(ngx.var.arg_subject_id)
local type_id = tostring(ngx.var.arg_type_id)

--章节还是知识点
local zj_zs = tostring(ngx.var.arg_zj_zs)
--local zj_zs = "3"
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

local ts = tostring(ngx.now()*1000)
--生成一个临时的有序集合key
local temp_key = cookie_person_id..ts

local result=""

local product_id = cache:get("subject_type_"..subject_id.."_"..type_id)
if product_id~=ngx.null then
local res_group = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id)
for i=1,#res_group do
    if zj_zs=="1" or zj_zs=="3" then	
    	local pg = cache:zrange("product_group_"..product_id.."_"..res_group[i].."_1",0,-1,"withscores")
    	if #pg~=0 then
	    for j=1,#pg,2 do
                local set_value = pg[j]
                local set_score = pg[j+1]
                cache:zadd(temp_key,set_score,set_value)
            end
    	end
    end

    if zj_zs=="2" or zj_zs=="3" then
        local pg = cache:zrange("product_group_"..product_id.."_"..res_group[i].."_2",0,-1,"withscores")
        if #pg~=0 then
            for j=1,#pg,2 do
                local set_value = pg[j]
                local set_score = pg[j+1]
                cache:zadd(temp_key,set_score,set_value)
            end 
        end
    end
end

local pg_temp = cache:zrange(temp_key,0,-1)

cache:del(temp_key)


for i=1,#pg_temp do
    result = result..pg_temp[i]..","
end
result = string.sub(result,0,#result-1)
end
ngx.say("{\"success\":true,\"version_list\":["..result.."]}")
