#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


--参数：app_type_id
if args["app_type_id"]==nil or args["app_type_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数app_type_id不能为空！");
    return
end
local app_type_id = tostring(args["app_type_id"]);

--参数：scheme_id
if args["scheme_id"]==nil or args["scheme_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数scheme_id不能为空！");
    return
end
local scheme_id = tostring(args["scheme_id"]);

--连接redis

local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

 --cache:hmset("t_base_apptype_"..scheme_id.."_"..app_prime_id,apptype_tab)
local app_type_info = cache:hmget("t_base_apptype_"..scheme_id.."_"..app_type_id,"app_type_name")

local app_type_name = app_type_info[1];
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"app_type_name\":\""..app_type_name.."\",\"app_type_id\":\""..app_type_id.."\"}");