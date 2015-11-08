--[[
根据区域均衡ID获取区域均衡信息
@Author  chenxg
@Date    2015-01-14
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
local region_id = args["region_id"]


--判断参数是否为空
if not region_id or string.len(region_id) == 0 
   then
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
local b, err = ssdb:hexists("qyjh_open", region_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

--获取详细信息
local qyjh = ssdb:hget("qyjh_qyjhs",region_id)
local temp = cjson.decode(qyjh[1])
temp.success = "true"

say(cjson.encode(temp))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
