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

--科目
local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
--系统
local system_id = tostring(args["type_id"])
if system_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end
--章节还是知识点
local zj_zs = tostring(args["zj_zs"])
if zj_zs == "nil" then
    ngx.say("{\"success\":false,\"info\":\"zj_zs参数错误！\"}")
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

--生成一个临时的有序集合key
local temp_key = cookie_person_id..tostring(ngx.now()*1000)

local result = ""

--根据科目ID和系统ID获取产品ID
local product_id = cache:get("subject_system_product_"..subject_id.."_"..system_id)

if product_id ~= ngx.null then

--根据产品ID获取结构（版本）
if zj_zs=="1" or zj_zs=="3" then
    local version_info = cache:zrange("product_scheme_"..product_id.."_1",0,-1,"withscores")
    if #version_info ~= 0 then
	for j=1,#version_info,2 do
            local set_value = version_info[j]
            local set_score = version_info[j+1]
            cache:zadd(temp_key,set_score,set_value)
        end
    end
end

if zj_zs=="2" or zj_zs=="3" then
    local version_info = cache:zrange("product_scheme_"..product_id.."_2",0,-1,"withscores")
    if #version_info ~= 0 then
        for j=1,#version_info,2 do
            local set_value = version_info[j]
            local set_score = version_info[j+1]
            cache:zadd(temp_key,set_score,set_value)
        end
    end
end

local version = cache:zrange(temp_key,0,-1)

--删除临时有序集合
cache:del(temp_key)

for i=1,#version do
    result = result..version[i]..","
end
result = string.sub(result,0,#result-1)

end
ngx.say("{\"success\":true,\"version_list\":["..result.."]}")

