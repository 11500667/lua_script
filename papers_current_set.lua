#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

ngx.req.read_body()
local args = ngx.req.get_post_args()
--subject_id参数
local subject_id = tostring(args["subject_id"])
--json_str参数
local json_str = tostring(args["json_str"])

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

-- json_str = ngx.decode_base64(json_str)
ngx.log(ngx.ERR, "===> 保存当前试卷json_str ===> ", json_str);

cache:set("papers_current_"..cookie_person_id.."_"..subject_id,json_str)
