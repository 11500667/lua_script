#ngx.header.content_type = "text/plain;charset=utf-8"

--UFT_CODE
function urlencode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--资源的info表id
local id = tostring(args["id"])
--判断是否有资源ID参数
if id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end

local down_path = ssdb_db:multi_hget("resource_"..id,"for_iso_url","for_urlencoder_url","resource_title")

local url_code = urlencode(down_path[6])
local down_path_json = "{\"success\":\"true\",\"for_iso_url\":\""..down_path[2].."\",\"for_urlencoder_url\":\""..down_path[4].."\",\"url_code\":\""..url_code.."\"}"

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say(down_path_json)
