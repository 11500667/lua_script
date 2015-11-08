--[[
编辑区域均衡
@Author  chenxg
@Date    2015-01-18
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
local name = args["name"]
local description = args["description"]
if not region_id or string.len(region_id) == 0 or not ab_id or string.len(ab_id) == 0 or not name or string.len(name) == 0 or not description or string.len(description) == 0 then
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
local b, err = ssdb:hexists("ab_region", region_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if b[1] == "0" then
	say("{\"success\":false,\"info\":\"尚未开通！\"}")
	return
end

--base64
description = ngx.encode_base64(description)
name = ngx.encode_base64(name)

--更新description
local wkrm, err = ssdb:hget("ab_abs", ab_id)
wkrm = cjson.decode(wkrm[1])
wkrm.description = description
wkrm.name = name

local ok, err = ssdb:hset("ab_abs", ab_id, cjson.encode(wkrm))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--return
say("{\"success\":true,\"info\":\"保存成功！\"}")


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)