--[[
根据region_id查询工作室详情
@Author  feiliming
@Date    2014-12-22
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local person_id = ngx.var.arg_person_id
local region_id = ngx.var.arg_region_id
if not region_id or string.len(region_id) == 0 then
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
--这个地区是否有工作室
local wkrm, err = ssdb:hget("workroom_region", region_id)
if not wkrm or string.len(wkrm[1]) == 0 then
	say("{\"success\":false,\"info\":\"未找到工作室！\"}")
    return
end

--有但关闭
local wr = cjson.decode(wkrm[1])
if wr.status ~= "1" then
	say("{\"success\":false,\"info\":\"工作室关闭了！\"}")
    return
end

local t_workroom = ssdb:hget("workroom_workrooms", wr.workroom_id)
local workroom = cjson.decode(t_workroom[1])

--访问次数+1
local t_wr_scan_count = ssdb:zget("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id)
if t_wr_scan_count and string.len(t_wr_scan_count[1]) > 0 then
	ssdb:zset("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id, tonumber(t_wr_scan_count[1]) + 1)
else
	ssdb:zset("workroom_"..workroom.level.."_sorted_by_scan_count", workroom.workroom_id, 1)
end
--总访问次数+1
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
	ngx.log(ngx.ERR, "cxg_log  getWorkroomDetailByRegionID ============> "..all_sql.."");
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

if person_id and string.len(person_id) ~= 0 then
	--是否名师, 名师id
	local t_teacherids, err = ssdb:hget("workroom_person_teacher", person_id)
	if string.len(t_teacherids[1]) ~= 0 then
		returnjson.isteacher = "1"
		--是否当前工作室
		local a_teacherids = Split(t_teacherids[1], ",")
		for i=1,#a_teacherids do
			local t_teacher, err = ssdb:hget("workroom_teachers", a_teacherids[i])
			local teacher = cjson.decode(t_teacher[1])
			if teacher.workroom_id == workroom.workroom_id then
				returnjson.teacher_id = teacher.teacher_id
				returnjson.iscur = "1"
				break
			end
		end
		--如果不是当前工作室的,则teacher_id截取第一个
		if not returnjson.iscur then
			returnjson.teacher_id = a_teacherids[1]
		end
	end
	--是否当前工作室名师
	--local wp = ssdb:hget("workroom_workroom_person", workroom.workroom_id.."_"..person_id)
	--if wp and wp[1] == "1" then
	--	returnjson.iscur = "1"
	--end

	--获取person_id详情, 调用java接口, 设置默认学段学科
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
	returnjson.default_stage_id = person.stage_id
	returnjson.default_subject_id = person.subject_id

	--最近访问
	local ts = os.date("%Y%m%d%H%M%S")
	ssdb:zset("workroom_recent_"..person_id, workroom.workroom_id, ts)	
end

if not returnjson.default_stage_id then
	returnjson.default_stage_id = "0"
end
if not returnjson.default_subject_id then
	returnjson.default_subject_id = "0"
end
if not returnjson.isteacher then
	returnjson.isteacher = "0"
end
if not returnjson.iscur then
	returnjson.iscur = "0"
end
if not returnjson.teacher_id then
	returnjson.teacher_id = "0"
end
if not returnjson.logo_url then
	returnjson.logo_url = ""
end

say(cjson.encode(returnjson))
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
