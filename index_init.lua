#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = "1"

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
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":false,\"info\":\"token参数错误！\"}")
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

local select_stage_id = "0"
local select_subject_id = "0"
local select_scheme_id = "0"
local select_structure_id = "0"

local history = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"stage_id","subject_id","scheme_id","pid_str","structure_id")
if tostring(history[1])~="userdata: NULL" then
    select_stage_id = history[1]
end
if tostring(history[2])~="userdata: NULL" then
    select_subject_id = history[2]
end
if tostring(history[3])~="userdata: NULL" then
    select_scheme_id = history[3]
end
if tostring(history[4])~="userdata: NULL" then
    select_structure_id = history[4]
end

local str_reslut = ""

local xdkm_res = cache:get("xd_subject")
local xdkm_select = "\"select_subject\":\""..select_subject_id.."\""
str_reslut = xdkm_res..","..xdkm_select

--获取一个两位随机数
local r = string.sub(math.random(),5,6)
--生成一个临时的有序集合key
local temp_key = os.time()+r

local product_id = cache:get("subject_type_"..select_subject_id.."_1")

local res_group = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id)
for i=1,#res_group do
    local pg = cache:zrange("product_group_"..product_id.."_"..res_group[i],0,-1,"withscores")
    if #pg~=0 then
        for j=1,#pg,2 do
            local set_value = pg[j]
            local set_score = pg[j+1]
            cache:zadd(temp_key,set_score,set_value)
        end
    end
end

local pg_temp = cache:zrange(temp_key,0,-1)

cache:del(temp_key)

local result=""

for i=1,#pg_temp do
    result = result..pg_temp[i]..","
end

result = string.sub(result,0,#result-1)


local root_tree = cache:get("scheme_structure_"..select_scheme_id)
local node_tree = cache:get("structure_async_"..select_structure_id)
--local node_tree = ""

ngx.say(str_reslut..",\"version_list\":["..result.."]},".."\"select_scheme\":\""..select_scheme_id.."\",\"tree_list\":"..root_tree..","..node_tree.."")
