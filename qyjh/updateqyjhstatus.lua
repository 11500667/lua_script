--[[
启用、停用区域均衡
@Author  chenxg
@Date    2015-01-08
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

local region_id = args["region_id"]
local b_use = args["b_use"]
if not region_id or string.len(region_id) == 0  or not b_use or string.len(b_use) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--判断是否已经开通
local qyjh, err = ssdb:hget("qyjh_qyjhs", region_id)
if not qyjh then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if string.len(qyjh[1]) == 0 then
	say("{\"success\":false,\"info\":\"尚未开通！\"}")
	return
end

--更新
local region = cjson.decode(qyjh[1])
region.b_use = b_use

ssdb:hset("qyjh_qyjhs", region_id, cjson.encode(region))

--return
say("{\"success\":true,\"b_use\":\""..region.b_use.."\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
