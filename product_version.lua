#ngx.header.content_type = "text/plain;charset=utf-8"

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

--平台
local plat_id = tostring(args["plat_id"])
if plat_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"plat参数错误！\"}")
    return
end
--版本类型
local version_id = tostring(args["version_id"])
if version_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"version参数错误！\"}")
    return
end
--知识点还是章节目录
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
local temp_key = ngx.time()..tostring(ngx.now()*1000)

local result = ""


local product_key = subject_id..system_id..plat_id..version_id
product_key = ngx.md5(product_key)
--根据科目ID和系统ID平台id版本类型id获得产品id
local product_id = cache:get("product_"..product_key)

if product_id == ngx.null then 
        ngx.say("{\"success\":false,\"info\":\"没有找到该产品\"}")
   return
end

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

--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":true,\"version_list\":["..result.."]}")


