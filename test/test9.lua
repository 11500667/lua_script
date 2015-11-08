
local cjson = require "cjson" 

local res = ngx.location.capture("/dsideal_yy/djmh/getNewsInfoByNewsId?id=122&random="..math.random(1000))

local str = res.body

local myTab = cjson.decode(str)

ngx.print(myTab.content);
