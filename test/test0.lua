--引入redis链接
local redis_pool = require("redis_pool")
local cache = redis_pool:get_connect()

local str = cache:get("node_18026")
ngx.say(str)

local str1 = cache:get("node_18027")
ngx.say(str1)
redis_pool:close()


local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


--获取节点id参数
local structure_id = tostring(args["structure_id"])
--判断节点id参数是否为空
if mediatype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"structure_id参数错误！\"}")
    return
end

-- 获取文件名称
local file_name = tostring(args["file_name"])
-- 判断文件名称是否为空
if file_name == 'nil' then 
	  ngx.say("{\"success\":false,\"info\":\"file_name参数错误！\"}")
    return




