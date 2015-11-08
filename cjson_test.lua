ngx.header.content_type = "text/plain;charset=utf-8"

local cjson = require "cjson"
--local str = {true, {foo="bar"}}
local str = "[true, {\"foo\":\"bar\"}]"
local result = cjson.decode(str)

result[2].foo="rab"

local aaa = result[2]

ngx.say(aaa.foo)

