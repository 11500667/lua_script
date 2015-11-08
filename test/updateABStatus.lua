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
local ab_id = args["ab_id"]
local status = args["status"]
if not region_id or string.len(region_id) == 0 or not ab_id or string.len(ab_id) == 0 or not status or string.len(status) == 0 then
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
local wkrm, err = ssdb:hget("ab_region", region_id)
if not wkrm then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if string.len(wkrm[1]) == 0 then
	say("{\"success\":false,\"info\":\"尚未开通！\"}")
	return
end

--更新
local region = cjson.decode(wkrm[1])
region.status = status

ssdb:hset("ab_region", region_id, cjson.encode(region))

--return
say("{\"success\":true,\"info\":\"保存成功！\"}")
say(cjson.encode(region))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
