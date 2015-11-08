local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

ngx.log(ngx.ERR,"------------aaaaaa-----------")

--判断参数是否正确
if tostring(args["user"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"user参数错误！\"}")    
    return
end
if tostring(args["pwd"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"pwd参数错误！\"}")
    return
end
--[[if tostring(args["mac"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"mac参数错误！\"}")
    return
end
if tostring(args["type"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end
]]
ngx.say("测试")
return 
