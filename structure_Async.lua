#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--ngx.req.read_body()
--local args = ngx.req.get_post_args()
local id = tostring(args["id"])
local scheme_id = tostring(args["scheme_id"])

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local str_result = ""
if id~="nil" then
    local child_id = cache:zrange("structure_child_"..id,0,-1)
    for i=1,#child_id do
        local isparent = "true"
        if tostring(cache:zcard("structure_child_"..child_id[i])) == "0" then
            isparent = "false"
        end
        local structure_info = cache:hmget("t_resource_structure_"..child_id[i],"structure_id","structure_name","structure_code")
        str_result = str_result.."{\"id\":\""..structure_info[1].."\",\"name\":\""..string.gsub(structure_info[2], "\"", "\\\"").."\",\"isParent\":"..isparent..",\"structure_code\":\""..structure_info[3].."\"},"
    end

    str_result = string.sub(str_result,0,#str_result-1)
    str_result = "["..str_result.."]"
    --str_result = cache:get("structure_async_"..id)
else
    str_result = cache:get("scheme_structure_"..scheme_id)
end
--redis放回连接池
cache:set_keepalive(0,v_pool_size);
ngx.print(str_result);

