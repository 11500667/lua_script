--[[
分页查询工作室下名师，将已经选中的打个标志
@Author  feiliming
@Date    2015-1-28
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local workroom_id = ngx.var.arg_workroom_id
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber
local level = ngx.var.arg_level

if not workroom_id or string.len(workroom_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	or not level or string.len(level) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--分页信息
local t_totalRow = ssdb:zcount("workroom_teachers_sorted_by_name_"..workroom_id, "", "")
local totalRow = t_totalRow[1]
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
if pageNumber > totalPage then
	pageNumber = totalPage
end
local offset = pageSize*pageNumber-pageSize
local limit = pageSize

--zscan查名师id,吗的没查到返回ok?
--zscan不能跳页,改成zrange,zrange全表扫描,适合几百条数据以下
--local res, err = ssdb:zscan("workroom_teachers_sorted_by_name_"..workroom_id, key_start, score_start, "", pageSize)
local res, err = ssdb:zrange("workroom_teachers_sorted_by_name_"..workroom_id, offset, limit)
if not res then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if res[1] == "ok" then
	local returnjson = {}
	returnjson.success = true
	returnjson.totalRow = 0
	returnjson.totalPage = 0
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	--returnjson.key_start = key_start
	--returnjson.score_start = score_start

	returnjson.list = {}
	cjson.encode_empty_table_as_object(false)
	say(cjson.encode(returnjson))
	return
end

local t_len = #res
local teacherids = {}
for i=1,t_len,2 do
	teacherids[#teacherids+1] = res[i]
	--下次查询使用
	--if i == t_len-1 then
	--	key_start = res[i]
	--	score_start = res[i+1]
	--end
end

--multi_hget查名师详细
local list = {}
local teachers, err = ssdb:multi_hget("workroom_teachers", unpack(teacherids))
local personids = {}
for i=1,#teachers,2 do
	local teacher = cjson.decode(teachers[i+1])
	list[#list+1] = teacher
	table.insert(personids, teacher.person_id)
end
	--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = table.concat(personids,",") }
})
if res_person.status == 200 then
    personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end
	--合并list和personlist
for i=1,#list do
	for j=1,#personlist do
		if list[i].person_id == tostring(personlist[j].person_id) then
			list[i].person_name = personlist[j].person_name
			list[i].school_id = personlist[j].bureau_id
			list[i].school_name = personlist[j].org_name
			list[i].stage_id = personlist[j].stage_id
			list[i].stage_name = personlist[j].stage_name
			list[i].subject_id = personlist[j].subject_id
			list[i].subject_name = personlist[j].subject_name
			break
		end
	end
end

--根据level查
local tids = {}
local z0 = ssdb:zrange("workroom_"..level.."_t_hot", 0, 100)
if z0 and z0[1] and z0[1] ~= "ok" then
	for i=1,#z0,2 do
		table.insert(tids, z0[i])
	end
end
for i=1,#list do
	local flag = 0
	for j=1,#tids do
		if list[i].teacher_id == tostring(tids[j]) then
			flag = 1
			break
		end
	end
	list[i].selected = flag
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
--returnjson.key_start = key_start
--returnjson.score_start = score_start
returnjson.list = list
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)
