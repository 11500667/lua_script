local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie信息person_id错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie信息identity_id错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local str= cache:hmget("cloud_space_personal_"..cookie_person_id.."_"..cookie_identity_id,"structure_id")[1];
if str==ngx.null then
 str =""
end;
--redis放回连接池
cache:set_keepalive(0,v_pool_size);
ngx.say("{\"success\":true,\"fileRootId\":\""..str.."\"}");
