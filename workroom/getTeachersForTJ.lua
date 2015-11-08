--[[
取工作室下名师
统计调用
@Author  feiliming
@Date    2014-12-4
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

--zscan查名师id,吗的没查到返回ok?
local res, err = ssdb:zscan("workroom_teachers_sorted_by_name_"..workroom_id, "", "", "", 10000)
if not res then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if res[1] == "ok" then
	local returnjson = {}
	returnjson.success = true
	returnjson.list = {}

	say(cjson.encode(returnjson))
	return
end

local t_len = #res
local teacherids = {}
for i=1,t_len,2 do
	teacherids[#teacherids+1] = res[i]
end

--multi_hget查名师详细
local list = {}
local teachers, err = ssdb:multi_hget("workroom_teachers", unpack(teacherids))
for i=1,#teachers,2 do
	local teacher = cjson.decode(teachers[i+1])
	local tp = {}
	tp.person_id = teacher.person_id
	list[#list+1] = tp
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.list = list

say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)
