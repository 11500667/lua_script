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

--require "LuaXml"

--local myxml = require "LuaXml"

if tostring(args["xml"])=="nil" then
   ngx.say("{\"success\":false,\"info\":\"user参数错误！\"}")    
   return
else
    local myxml = args["xml"];
    ngx.log(ngx.ERR,"------------bbbbbb-----------",myxml)
end

ngx.say(cjson.encode("测试"))
return 
