--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson"

local res = cache:get("stage_subject_info")

local reslut = {}

reslut["success"] = true
reslut["subject_list"] = cjson.decode(res)

ngx.print(cjson.encode(reslut))

