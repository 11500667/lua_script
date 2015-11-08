--[[
查工作室,后台编辑前调用
@Author  feiliming
@Date    2014-12-3
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local workroom_id = ngx.var.arg_workroom_id
if not workroom_id or string.len(workroom_id) == 0 then
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

--
local wr, err = ssdb:hget("workroom_workrooms", workroom_id)
if not wr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local workroom = cjson.decode(wr[1])

local returnjson = {}
returnjson.success = true
returnjson.workroom_id = workroom_id
returnjson.name = workroom.name
returnjson.logo_url = workroom.logo_url
returnjson.description = workroom.description

say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)
