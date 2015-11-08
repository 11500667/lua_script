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

local str= "{\"success\":true,\"quotaTotal\":\"##\",\"quotaUsed\":\"##\",\"totalSpace\":\"##\",\"useSpace\":\"##\",\"cloud_percent\":\"##\"}";
local cloud_info_person = cache:hmget("cloud_space_personal_"..cookie_person_id.."_"..cookie_identity_id,"quotaTotal","quotaUsed","totalSpace","useSpace","cloud_percent");
for i=1,#cloud_info_person do
  if cloud_info_person[i]==ngx.null then
    str =string.gsub(str,"##","");
  else
    str = string.gsub(str,"##",cloud_info_person[i],1);
  end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say(str);


