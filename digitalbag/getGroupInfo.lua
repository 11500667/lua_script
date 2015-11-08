local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local str_reslut=""
--虚拟群组
local group_qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
str_reslut = str_reslut.."{\"group_id\":\""..group_qu.."\",\"group_name\":\"本区\"},"
local group_xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
str_reslut = str_reslut.."{\"group_id\":\""..group_xiao.."\",\"group_name\":\"本校\"},"
local group_bm = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")
str_reslut = str_reslut.."{\"group_id\":\""..group_bm.."\",\"group_name\":\"教研室\"},"

--自定义群组
local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
for i=1,#group_list do
    local groupname = cache:hmget("groupinfo_"..group_list[i],"org_name","b_use","source_id")
    if groupname[2]=="1" and groupname[3]=="1" then
        str_reslut = str_reslut.."{\"group_id\":\""..group_list[i].."\",\"group_name\":\""..groupname[1].."\"},"
    end
end

str_reslut = string.sub(str_reslut,0,#str_reslut-1)

ngx.say("{\"success\":true,\"group_List\":["..str_reslut.."]}")
