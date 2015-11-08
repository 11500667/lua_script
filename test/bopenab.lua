--[[
判断管理员所在的地区是否已经开通区域均衡
@Author  chenxg
@Date    2015-01-08
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"


--获得get请求参数
--local person_id = ngx.var.arg_person_id
local region_id = ngx.var.arg_region_id
if not region_id or string.len(region_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
ssdb:set_timeout(3000) --不设置也可以, 默认2000
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--判断region_id是否存在, 存在则返回workroom_id和status
local ab, err = ssdb:hget("ab_region", region_id)
if not ab then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--say(#ab) --返回1, 即使键值不存在table里也存了一个空串"", 类型为string, cjson.encode()后也是string, 所以可以用string.len()
local returnjson = {}
if string.len(ab[1]) == 0 then
	returnjson.success = true
	returnjson.bopen = "0"
else
	--hset的时候encode
	local temp = cjson.decode(ab[1])
	returnjson.success = true
	returnjson.bopen = "1"	
	returnjson.ab_id  = temp.ab_id
	local t_w = ssdb:hget("ab_abs", temp.ab_id)
	local w = cjson.decode(t_w[1])
	returnjson.name = w.name
	returnjson.status = temp.status
end

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)