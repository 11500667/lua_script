--[[
根据当前用户获取用户的信息，现在初期提供所在省市区
@Author  chenxg
@Date    2015-02-06
--]]
local say = ngx.say

--引用模块
local cjson = require "cjson"

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local returnjson = {}
--参数 
--当前用户ID
local person_id = args["person_id"]

-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

local sheng = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
local shi = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
local qu = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")

local returnjson = {}
returnjson.success = true
returnjson.sheng = sheng
returnjson.shi = shi
returnjson.qu = qu
say(cjson.encode(returnjson))

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end