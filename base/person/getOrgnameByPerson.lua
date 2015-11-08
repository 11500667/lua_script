#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-04-15
#描述：根据人员id获得对应的组织机构名称
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数person_id不能为空！\"}");
    return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
    return;
end
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local personId   = tostring(args["person_id"]);
local identityId = tostring(args["identity_id"]);
--ngx.log(ngx.ERR,"*************".."person_"..personId.."_"..identityId)
local xiao = cache:hget("person_"..personId.."_"..identityId,"xiao");
local org_name = "未知";
if xiao ~= ngx.null then
  org_name= cache:hget("t_base_organization_"..xiao,"org_name")
end
 org_name = string.gsub(org_name,"唐山市","",1)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
ngx.print(org_name);
