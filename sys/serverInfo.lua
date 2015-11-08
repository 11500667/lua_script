#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-18
#描述：记录系统的ip和端口
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

--传参数
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

if args["server_url"] == nil or args["server_url"] == "" then
    ngx.say("{\"success\":false,\"info\":\"server_url参数错误！\"}")
    return
end
local server_url  = tostring(args["server_url"]);

local resultJson={};
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local serverinfo="";
if type_id == "1" then
cache:set("server_url",server_url)
elseif type_id == "2" then
serverinfo = cache:get("server_url")
end
resultJson.success = true;
resultJson.server_url = serverinfo;
-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

ngx.say(responseJson);
