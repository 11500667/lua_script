--[[
按访问次数查看工作室
@Author  feiliming
@Date    2014-12-30
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local limit = ngx.var.arg_limit
local person_id = ngx.var.arg_person_id
if not limit or string.len(limit) == 0 then
	limit = 5
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local res, err = ssdb:zrrange("workroom_0_sorted_by_scan_count", 0, limit)
local list = {}
if res and res[1] and res[1] ~= "ok" then
	for i=1,#res,2 do
		if res[i] then
			local tw = ssdb:hget("workroom_workrooms", res[i])
			if tw and tw[1] then
				local wr = cjson.decode(tw[1])
				local workroom = {}
				workroom.workroom_id = wr.workroom_id
				workroom.name = wr.name
				list[#list+1] = workroom
			end
		end
	end
end

local list2 = {}
if person_id and string.len(person_id) > 0 then
	local res2, err = ssdb:zrrange("workroom_recent_"..person_id, 0, limit)
	if res2 and res2[1] and res2[1] ~= "ok" then
		for i=1,#res2,2 do
			if res2[i] then
				local tw = ssdb:hget("workroom_workrooms", res2[i])
				if tw and tw[1] then
					local wr = cjson.decode(tw[1])
					local workroom = {}
					workroom.workroom_id = wr.workroom_id
					workroom.name = wr.name
					list2[#list2+1] = workroom
				end
			end
		end
	end
end

local returnjson = {}
returnjson.success = true
returnjson.list = list
returnjson.list2 = list2
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)