ngx.header.content_type = "text/plain;charset=utf-8"
local date = require "date"

local localtime = ngx.localtime()

ngx.update_time()
local ts = tostring(ngx.now()*1000)
ngx.say(ts)

ngx.say(tostring(ngx.utctime()))

