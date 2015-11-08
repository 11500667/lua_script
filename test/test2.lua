local redis_pool = require("redis_pool")
local cache = redis_pool:get_connect()
local str = cache:get("node_18026")
ngx.say(str)

local str1 = cache:get("node_18027")
ngx.say(str1)
redis_pool:close()
