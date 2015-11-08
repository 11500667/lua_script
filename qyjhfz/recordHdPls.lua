--[[
记录活动的评论数
@Author  chenxg
@Date    2015-03-09
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
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
--参数 
local hd_id = args["hd_id"]

--判断参数是否为空
if not hd_id or string.len(hd_id) == 0
   then
    say("{\"success\":false,\"info\":\"hd_id参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--点击量加1
ssdb:zincr("qyjh_hd_pls", hd_id,1)
local pls = ssdb:zget("qyjh_hd_pls", hd_id)
say("{\"success\":true,\"pls\":\""..pls[1].."\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
