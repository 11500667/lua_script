local tab ={}
tab["Himi"] = "himigame.com"
--数据转json
local cjson = require "cjson"
local jsonData = cjson.encode(tab)
 
ngx.say(jsonData)
-- 打印结果:  {"Himi":"himigame.com"}
 
--json转数据
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

cache:set("ceshiceshiceshi",jsonData)
local aaaaa = cache:get("ceshiceshiceshi")

local data = cjson.decode(aaaaa)
 --redis放回连接池
cache:set_keepalive(0,v_pool_size)
ngx.say(data.Himi) 
-- 打印结果:  himigame.com
