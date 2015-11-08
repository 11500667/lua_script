--[[
@Author chuzheng
@date 2015-2-13
--]]
local say = ngx.say

--引用
local ssdblib = require "resty.ssdb"

--前台接参数
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


local id = args["id"]

if not id or string.len(id) == 0  then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
        return
end

--建立ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
ssdb:hdel("yxx_game_applicationrange",id )

say("{\"success\":true,\"info\":\"删除成功！\"}")

ssdb:set_keepalive(0,v_pool_size)
