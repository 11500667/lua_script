--[[
记录大学区的点击量
@Author  chenxg
@Date    2015-01-26
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
local dxq_id = args["dxq_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0
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

local hdxq = ssdb:hget("qyjh_dxq",dxq_id)
local dxq = cjson.decode(hdxq[1])
local qyjh_id = dxq.qyjh_id

--获取点击量，然后点击量加1
local tdjl = ssdb:zget("qyjh_dxq_djl_"..qyjh_id, dxq_id)
local djl = 0
if not tdjl[1] or string.len(tdjl[1]) == 0 then
	djl = 0
else
	djl = tonumber(tdjl[1])
end
ssdb:zset("qyjh_dxq_djl_"..qyjh_id, dxq_id,djl+1)
say("{\"success\":true}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
