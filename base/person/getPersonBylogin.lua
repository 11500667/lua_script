#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


--参数：login_name
if args["login_name"]==nil or args["login_name"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数login_name不能为空！");
    return
end
local login_name = tostring(args["login_name"]);

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local logininfo = cache:hmget("login_"..login_name,"person_id","identity_id","person_name");
 if tostring(logininfo[1]) == "userdata: NULL" then
      ngx.say("{\"success\":\"false\",\"info\":\"不存在此用户\"}")
    return
 end
 
 local avatarUrl = cache:hget("person_"..logininfo[1].."_"..logininfo[2], "avatar_url");
 
ngx.say("{\"success\":\"true\",\"person_id\":\""..logininfo[1].."\",\"identity_id\":\""..logininfo[2].."\",\"person_name\":\""..logininfo[3].."\",\"avatar_url\":\""..avatarUrl.."\"}")

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end
