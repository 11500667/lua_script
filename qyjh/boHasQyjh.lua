--[[
根据区域ID判断该区域是否开通区域均衡
@Author  chenxg
@Date    2015-02-06
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

--判断region_id是否存在, 存在则返回qyjh_id,b_use,b_open,name
local qyjh, err = ssdb:hget("qyjh_open", region_id)
if not qyjh then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--say(#ab) --返回1, 即使键值不存在table里也存了一个空串"", 类型为string, cjson.encode()后也是string, 所以可以用string.len()
local returnjson = {}
if string.len(qyjh[1]) == 0 then
	returnjson.success = false
else
	local qyjhs = ssdb:hget("qyjh_qyjhs",region_id)
	local temp = cjson.decode(qyjhs[1])
	if temp.b_use == "0" then
		returnjson.success = false
	else
		returnjson.success=true
	end

end

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)