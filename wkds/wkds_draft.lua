#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"token参数错误！\"}")
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

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--获得subject_id
local subject_id = tostring(args["subject_id"])
--判断是否有subject_id参数
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
--获得微课id
local id = cache:get("wkds_current_"..subject_id.."_"..cookie_person_id.."_"..cookie_identity_id)
  if id==ngx.null then
    ngx.say("{\"success\":\"false\",\"info\":\"该科目下没有草稿！\"}")
    return
   end

local wkds_draft = cache:hmget("wkds_"..id,"content_json")
     if wkds_draft[1]==ngx.null then
        ngx.say("{\"success\":\"false\",\"info\":\"无法获得草稿信息\"}")
        return
     end
local wkds_draft_base = ngx.decode_base64(wkds_draft[1])
--ngx.say(wkds_draft_base)
local wkds_draft_json = "{\"success\":\"true\",\"wkds_draft\":"..wkds_draft_base.."}"
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
ngx.say(wkds_draft_json)


