--[[
判断当前用户是否名师
@Author  feiliming
@Date    2014-12-1
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local person_id = ngx.var.arg_person_id
if not person_id or string.len(person_id) == 0 then
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

--判断
local res, err = ssdb:hget("workroom_person_teacher", person_id)
if not res then
	say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if string.len(res[1]) ~= 0 then
	say("{\"success\":true,\"bteacher\":\"1\"}")
else
	say("{\"success\":true,\"bteacher\":\"0\"}")
end

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)