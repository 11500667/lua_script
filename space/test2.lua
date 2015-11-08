--[[
feiliming 测试
2015-6-2
]]

local aService = require "space.services.PersonAndOrgBaseInfoService"
local r = aService:getOrgBaseInfo("3005291", "103")
local name = r and r.name or "失败"
local date = aService._Date
ngx.say(name)
ngx.say(date)
ngx.say(aService._Description)
local cjson = require "cjson"
ngx.say(cjson.encode(r))



local rr = aService:getPersonBaseInfo("301631", "5")
ngx.say(cjson.encode(rr))