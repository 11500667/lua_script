#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil

if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
	ngx.log(ngx.ERR,ngx.req.get_post_args());
    args = ngx.req.get_post_args()
end

if args["person_id"]==nil  then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = tostring(args["person_id"])  
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local str= cache:hmget("cloud_space_personal_"..person_id.."_"..5,"structure_id")[1];
if str==ngx.null then
 str =""
end;
--redis放回连接池
cache:set_keepalive(0,v_pool_size);
ngx.say("{\"success\":true,\"fileRootId\":\""..str.."\"}");
