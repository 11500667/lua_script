--[[
统计总工作室和总名师数
@Author feiliming
@Date   2015-1-5
]]
local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local w_size = ssdb:hsize("workroom_workrooms")
local t_size = ssdb:hsize("workroom_teachers")
if not w_size or not t_size then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.workroom_count = w_size[1]
returnjson.teacher_count = t_size[1]

say(cjson.encode(returnjson))
ssdb:set_keepalive(0,v_pool_size)