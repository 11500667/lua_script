#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_avatar_url = tostring(ngx.var.cookie_avatar_url)

--会话ID
local chat_id = tostring(ngx.var.arg_chat_id)
--会话类型  3：群组  4：好友
local type_id = tostring(ngx.var.arg_type_id)
--会话人
local chat_name = ngx.decode_base64(tostring(ngx.var.arg_chat_name))
--会话内容
local chat_content = tostring(ngx.var.arg_chat_content)

chat_content = ngx.decode_base64(chat_content)

chat_content = string.gsub (chat_content, "\n", "")
chat_content = string.gsub (chat_content, "\r", "")

--时间截
local ts = tostring(ngx.now()*1000)
--发送时间
local send_time = tostring(ngx.localtime())


--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local chat_url = cache:hmget("person_"..cookie_person_id.."_"..cookie_identity_id,"avatar_url")[1]

--向一个有序集合中插入
cache:zadd("msgContent_"..chat_id,ts,"{\"chat_id\":\""..chat_id.."\",\"chat_name\":\""..chat_name.."\",\"chat_content\":\""..chat_content.."\",\"chat_time\":\""..send_time.."\",\"send_person\":\""..cookie_person_id.."\",\"send_identity\":\""..cookie_identity_id.."\",\"ts\":\""..ts.."\",\"chat_url\":\""..chat_url.."\"}")


--写队列
local str = "{\"action\":\"sp_add_msg\",\"need_newcache\":\"0\",\"paras\":{\"v_CHAT_ID\":\""..chat_id.."\",\"v_MSG_TYPE\":\""..type_id.."\",\"v_MSG_CONTENT\":\""..chat_content.."\",\"v_SEND_TIME\":\""..send_time.."\",\"v_ts\":\""..ts.."\",\"v_PERSON_ID\":\""..cookie_person_id.."\",\"v_PERSON_NAME\":\""..chat_name.."\",\"v_IDENTITY_ID\":\""..cookie_identity_id.."\",\"v_SYS_MSG_CODE\":\"000000\",\"v_AVATAR_URL\":\""..cookie_avatar_url.."\"}}"

cache:lpush("async_write_list",str)

ngx.say("ok")
