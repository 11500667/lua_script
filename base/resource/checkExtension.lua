#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-04
#描述：判断该扩展名的资源是否允许上传
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

 --连接redis
local redis = require "resty.redis"
local cache = redis:new();
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--传参数
--extension 
if args["extension"] == nil or args["extension"] == "" then
    ngx.say("{\"success\":false,\"info\":\"extension参数错误！\"}")
    return
end
local extension = args["extension"]
local b_exists = cache:exists("t_resource_extension_"..extension)

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end
if b_exists==1 then
    ngx.say("{\"success\":true,\"info\":\"该扩展名可以上传\"}");
else
    ngx.say("{\"success\":false,\"info\":\"该扩展名不允许上传\"}");
end 











