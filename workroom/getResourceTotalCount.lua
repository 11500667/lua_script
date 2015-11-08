local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local resource_count = ssdb_db:hget("workroom_tj_all","resource_count")[1]

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true,\"resource_count\":\""..resource_count.."\"}")