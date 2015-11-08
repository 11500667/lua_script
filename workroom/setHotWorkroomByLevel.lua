--[[
设置某个级别(0,1,2,3)下的最热工作室
@Author feiliming
@Date   2015-1-12
]]
local say = ngx.say
local len = string.len

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

local level = args["level"]
local list = args["list"]
if not level or len(level) == 0 or
	not list or len(list) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
end

local t_list = cjson.decode(list)
if not t_list then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据level查, 然后删除
local limit = 100
local z0 = ssdb:zrange("workroom_"..level.."_w_hot", 0, limit)
if z0 and z0[1] and z0[1] ~= "ok" then
	local wids = {}
	for i=1,#z0,2 do
		table.insert(wids, z0[i])
	end
	--删除
	ssdb:multi_zdel("workroom_"..level.."_w_hot", unpack(wids))
end

--重新set
for i=1,#t_list.list do
	ssdb:zset("workroom_"..level.."_w_hot", t_list.list[i].workroom_id, t_list.list[i].order)
end

say("{\"success\":true,\"info\":\"保存成功！\"}")
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)