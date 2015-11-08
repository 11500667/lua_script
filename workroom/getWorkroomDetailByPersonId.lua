--[[
根据person_id查询工作室详情
@Author  feiliming
@Date    2014-12-3
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
--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end
--获取person_id详情, 调用java接口
local person
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = person_id }
})
if res_person.status == 200 then
    person = cjson.decode(res_person.body)[1]
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end

local isteacher = 0
local iscur = 0
--找所属工作室,找第一个status=1的
local t_teacherids, err = ssdb:hget("workroom_person_teacher", person_id)
local workroom_id
local workroom
local teacher_id

if string.len(t_teacherids[1]) ~= 0 then
	isteacher = 1
	local a_teacherids = Split(t_teacherids[1], ",")
	for i=1,#a_teacherids do
		local t_teacher, err = ssdb:hget("workroom_teachers", a_teacherids[i])
		local teacher = cjson.decode(t_teacher[1])
		teacher_id = teacher.teacher_id
		local tw, err = ssdb:hget("workroom_workrooms", teacher.workroom_id)
		workroom = cjson.decode(tw[1])
		local twr, err = ssdb:hget("workroom_region", workroom.region_id)
		local wr = cjson.decode(twr[1])
		if tostring(wr.status) == "1" then
			workroom_id = workroom.workroom_id
			--是否当前工作室名师
			local wp = ssdb:hget("workroom_workroom_person", teacher.workroom_id.."_"..person_id)
			if wp and wp[1] == "1" then
				iscur = "1"
			end
			break
		end
	end
end

if workroom_id then

	--访问次数+1
	local t_wr_scan_count = ssdb:zget("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id)
	if t_wr_scan_count and string.len(t_wr_scan_count[1]) > 0 then
		ssdb:zset("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id, tonumber(t_wr_scan_count[1]) + 1)
	else
		ssdb:zset("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id, 1)
	end
	--总的访问次数+1
	local t_wr_scan_count = ssdb:zget("workroom_0_sorted_by_scan_count", workroom.workroom_id)
	if t_wr_scan_count and string.len(t_wr_scan_count[1]) > 0 then
		ssdb:zset("workroom_0_sorted_by_scan_count", workroom.workroom_id, tonumber(t_wr_scan_count[1]) + 1)
	else
		ssdb:zset("workroom_0_sorted_by_scan_count", workroom.workroom_id, 1)
	end	

	-- 名师工作室 学段学科教师统计 陈续刚 2015.08.15 开始
	local base_sql = "SELECT IFNULL(st.STAGE_NAME,'全部')as stage_name,IFNULL(st.stage_id,0) as stage_id,teacher_count as teacher_num from t_base_workroom_tj wt left join t_dm_stage st on st.STAGE_ID = wt.stage_id where wt.workroom_id = "..workroom.workroom_id.." and wt.subject_id=0 GROUP BY stage_name,stage_id";
	local base_result = db:query(base_sql)

	local all_sql = "SELECT IFNULL(st.STAGE_NAME,'全部')as stage_name,IFNULL(st.stage_id,0) as stage_id,ifnull(su.SUBJECT_NAME,'全部')as subject_name,ifnull(su.subject_id,0)as subject_id,teacher_count as teacher_num from t_base_workroom_tj wt left join t_dm_stage st on st.STAGE_ID = wt.stage_id LEFT JOIN t_dm_subject su on wt.subject_id = su.subject_id where wt.workroom_id = "..workroom.workroom_id.." and teacher_count>0";
	local all_result = db:query(all_sql)
	ngx.log(ngx.ERR, "cxg_log  getWorkroomDetailByPersonId =====> "..all_sql.."");
	local stage = {}
	if base_result and #base_result>=1 and all_result and #all_result>=1 then
		for i=1,#base_result do
			local base_stage = {}
			base_stage.stage_name = base_result[i]["stage_name"]
			base_stage.stage_id = tonumber(base_result[i]["stage_id"])
			base_stage.teacher_num = tonumber(base_result[i]["teacher_num"])
			local all_subject = {}
			for j=1,#all_result do
				local stage_id = tonumber(all_result[j]["stage_id"])
				local subject_id = tonumber(all_result[j]["subject_id"])
				local subject_name = all_result[j]["subject_name"]
				local teacher_num = tonumber(all_result[j]["teacher_num"])
				if base_stage.stage_id == stage_id then
					local base_subject = {}
					base_subject.subject_name = subject_name
					base_subject.subject_id = subject_id
					base_subject.teacher_num = teacher_num
					all_subject[#all_subject+1] = base_subject
				end
			end
			base_stage.subject = all_subject
			stage[i] = base_stage
		end
	end

	--ngx.log(ngx.ERR, "stage =====> "..cjson.encode(stage));
	-- 名师工作室 学段学科教师统计 陈续刚 2015.08.15 结束
	
	
	local returnjson = {}
	returnjson.success = true
	returnjson.workroom_id = workroom.workroom_id
	returnjson.name = workroom.name
	returnjson.logo_url = workroom.logo_url
	returnjson.region_id = workroom.region_id
	returnjson.description = workroom.description
	--returnjson.stage = workroom.stage
	returnjson.stage = stage
	returnjson.default_stage_id = person.stage_id
	returnjson.default_subject_id = person.subject_id
	returnjson.isteacher = isteacher
	returnjson.iscur = iscur
	returnjson.teacher_id = teacher_id
	if not returnjson.logo_url then
		returnjson.logo_url = ""
	end

	say(cjson.encode(returnjson))
	ssdb:set_keepalive(0,v_pool_size)
	return
end

--判断区、市、省开通
local workroom
local ex = false
if not ex then
	local b, err = ssdb:hexists("workroom_region", person.district_id)
	if b[1] == "1" then	
		local twr, err = ssdb:hget("workroom_region", person.district_id)
		local wr = cjson.decode(twr[1])
		if wr.status == "1" then
			ex = true
			local tw = ssdb:hget("workroom_workrooms", wr.workroom_id)
			workroom = cjson.decode(tw[1])
		end
	end
end
if not ex then
	local b, err = ssdb:hexists("workroom_region", person.city_id)
	if b[1] == "1" then
		local twr, err = ssdb:hget("workroom_region", person.city_id)
		local wr = cjson.decode(twr[1])
		if wr.status == "1" then
			ex = true
			local tw = ssdb:hget("workroom_workrooms", wr.workroom_id)
			workroom = cjson.decode(tw[1])
		end
	end
end
if not ex then
	local b, err = ssdb:hexists("workroom_region", person.province_id)
	if b[1] == "1" then
		local twr, err = ssdb:hget("workroom_region", person.province_id)
		local wr = cjson.decode(twr[1])
		if wr.status == "1" then
			ex = true
			local tw = ssdb:hget("workroom_workrooms", wr.workroom_id)
			workroom = cjson.decode(tw[1])
		end
	end
end

if workroom then

	--访问次数+1
	local t_wr_scan_count = ssdb:zget("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id)
	if t_wr_scan_count and string.len(t_wr_scan_count[1]) > 0 then
		ssdb:zset("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id, tonumber(t_wr_scan_count[1]) + 1)
	else
		ssdb:zset("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id, 1)
	end
	--总的访问次数+1
	local t_wr_scan_count = ssdb:zget("workroom_0_sorted_by_scan_count", workroom.workroom_id)
	if t_wr_scan_count and string.len(t_wr_scan_count[1]) > 0 then
		ssdb:zset("workroom_0_sorted_by_scan_count", workroom.workroom_id, tonumber(t_wr_scan_count[1]) + 1)
	else
		ssdb:zset("workroom_0_sorted_by_scan_count", workroom.workroom_id, 1)
	end
	--最近访问
	local ts = os.date("%Y%m%d%H%M%S")
	ssdb:zset("workroom_recent_"..person_id, workroom.workroom_id, ts)		

	
	-- 名师工作室 学段学科教师统计 陈续刚 2015.08.15 开始
	local base_sql = "SELECT IFNULL(st.STAGE_NAME,'全部')as stage_name,IFNULL(st.stage_id,0) as stage_id,teacher_count as teacher_num from t_base_workroom_tj wt left join t_dm_stage st on st.STAGE_ID = wt.stage_id where wt.workroom_id = "..workroom.workroom_id.." and wt.subject_id=0 GROUP BY stage_name,stage_id";
	local base_result = db:query(base_sql)

	local all_sql = "SELECT IFNULL(st.STAGE_NAME,'全部')as stage_name,IFNULL(st.stage_id,0) as stage_id,ifnull(su.SUBJECT_NAME,'全部')as subject_name,ifnull(su.subject_id,0)as subject_id,teacher_count as teacher_num from t_base_workroom_tj wt left join t_dm_stage st on st.STAGE_ID = wt.stage_id LEFT JOIN t_dm_subject su on wt.subject_id = su.subject_id where wt.workroom_id = "..workroom.workroom_id.." and teacher_count>0";
	local all_result = db:query(all_sql)
	ngx.log(ngx.ERR, "cxg_log  getWorkroomDetailByPersonId =====> "..all_sql.."");
	local stage = {}
	if base_result and #base_result>=1 and all_result and #all_result>=1 then
		for i=1,#base_result do
			local base_stage = {}
			base_stage.stage_name = base_result[i]["stage_name"]
			base_stage.stage_id = tonumber(base_result[i]["stage_id"])
			base_stage.teacher_num = tonumber(base_result[i]["teacher_num"])
			local all_subject = {}
			for j=1,#all_result do
				local stage_id = tonumber(all_result[j]["stage_id"])
				local subject_id = tonumber(all_result[j]["subject_id"])
				local subject_name = all_result[j]["subject_name"]
				local teacher_num = tonumber(all_result[j]["teacher_num"])
				if base_stage.stage_id == stage_id then
					local base_subject = {}
					base_subject.subject_name = subject_name
					base_subject.subject_id = subject_id
					base_subject.teacher_num = teacher_num
					all_subject[#all_subject+1] = base_subject
				end
			end
			base_stage.subject = all_subject
			stage[i] = base_stage
		end
	end

	--ngx.log(ngx.ERR, "stage =====> "..cjson.encode(stage));
	-- 名师工作室 学段学科教师统计 陈续刚 2015.08.15 结束
	
	
	local returnjson = {}
	returnjson.success = true
	returnjson.workroom_id = workroom.workroom_id
	returnjson.name = workroom.name
	returnjson.logo_url = workroom.logo_url
	returnjson.region_id = workroom.region_id
	returnjson.description = workroom.description
	--returnjson.stage = workroom.stage
	returnjson.stage = stage
	returnjson.default_stage_id = person.stage_id
	returnjson.default_subject_id = person.subject_id
	returnjson.isteacher = "0"
	returnjson.iscur = "0"
	returnjson.teacher_id = "0"
	if not returnjson.logo_url then
		returnjson.logo_url = ""
	end

	ssdb:set_keepalive(0,v_pool_size)
	say(cjson.encode(returnjson))
	return
end

say("{\"success\":false,\"info\":\"未找到工作室！\"}")
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
