--[[
记录协作体的点击量
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
local xzt_id = args["xzt_id"]

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
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

local hxzt = ssdb:hget("qyjh_xzt",xzt_id)
local xzt = cjson.decode(hxzt[1])
local qyjh_id = xzt.qyjh_id
local dxq_id = xzt.dxq_id
--获取点击量，然后点击量加1
--按照区域均衡记录
local tdjl = ssdb:zget("qyjh_qyjh_xzt_djl_"..qyjh_id, xzt_id)
local djl = 0
if not tdjl[1] or string.len(tdjl[1]) == 0 then
	djl = 0
else
	djl = tonumber(tdjl[1])
end
ssdb:zset("qyjh_qyjh_xzt_djl_"..qyjh_id, xzt_id,djl+1)
ssdb:zset("qyjh_dxq_xzt_djl_"..dxq_id, xzt_id,djl+1)
say("{\"success\":true,\"djl\":"..djl.."}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
