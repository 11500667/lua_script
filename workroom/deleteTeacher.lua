--[[
删除名师
@Author feiliming
@Date   2014-12-4
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local teacher_id = args["teacher_id"]
if not teacher_id or string.len(teacher_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--找名师
local res, err = ssdb:hget("workroom_teachers", teacher_id)
if not res or string.len(res[1]) == 0 then
    say("{\"success\":false,\"info\":\"名师不存在！\"}")
    return
end

local teacher = cjson.decode(res[1])
local person_id = teacher.person_id
local workroom_id = teacher.workroom_id

--获取person_id详情, 调用java接口
local person
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = person_id }
})
if res_person.status == 200 then
    person = cjson.decode(res_person.body)[1]
else
	say("{\"success\":false,\"info\":\"删除失败！\"}")
    return
end

--3
local person_teacher_t = ssdb:hget("workroom_person_teacher", person_id)
local teacherids = ""
if string.len(person_teacher_t[1]) ~= 0 then
	local a_teacherids = Split(person_teacher_t[1], ",")
	for i=1,#a_teacherids do
		if tostring(a_teacherids[i]) ~= teacher_id then
			teacherids = a_teacherids[i]..","
		end
	end
end
if string.len(teacherids) > 0 then
	teacherids = string.sub(teacherids, 1, string.len(teacherids)-1)
end
--5
local t_workroom, err = ssdb:hget("workroom_workrooms", workroom_id)
local workroom = cjson.decode(t_workroom[1])
local t_stage = workroom.stage
for i=1,#t_stage do
	--stage -1
	if tostring(t_stage[i].stage_id) == "0" then
		if t_stage[i].teacher_num > 0 then
			t_stage[i].teacher_num = t_stage[i].teacher_num - 1
		end
		--subject -1
		local t_subject = t_stage[i].subject
		for j=1,#t_subject do
			if t_subject[j].subject_id == "0" then
				if t_stage[i].subject[j].teacher_num > 0 then
					t_stage[i].subject[j].teacher_num = t_stage[i].subject[j].teacher_num - 1
				end
			end
		end
	--stage -1
	elseif tostring(t_stage[i].stage_id) == tostring(person.stage_id) then
		if t_stage[i].teacher_num > 0 then
			t_stage[i].teacher_num = t_stage[i].teacher_num - 1
		end
		if t_stage[i].teacher_num == 0 then
			table.remove(t_stage, i)
			break
		end
		--subject -1
		local t_subject = t_stage[i].subject
		for j=1,#t_subject do
			if t_subject[j].subject_id == "0" then
				if t_stage[i].subject[j].teacher_num > 0 then
					t_stage[i].subject[j].teacher_num = t_stage[i].subject[j].teacher_num - 1
				end
			end
			if tostring(t_subject[j].subject_id) == tostring(person.subject_id) then
				if t_stage[i].subject[j].teacher_num > 0 then
					t_stage[i].subject[j].teacher_num = t_stage[i].subject[j].teacher_num - 1
				end
				if t_stage[i].subject[j].teacher_num == 0 then
					table.remove(t_stage[i].subject, j)
					break
				end
			end
		end
	end
end
workroom.stage = t_stage

--del:1名师, 2工作室和person多对多, 3person是否名师一对多, 
--4工作室下名师按姓排序, 5工作室学段学科, 678工作室学段学科下名师
--9名师区市省最新, 10名师最新, 11最热名师, 12省市区最热名师
ssdb:init_pipeline()
ssdb:hdel("workroom_teachers", teacher_id)
ssdb:hdel("workroom_workroom_person", workroom_id.."_"..person_id)
ssdb:hset("workroom_person_teacher", person_id, teacherids)
ssdb:zdel("workroom_teachers_sorted_by_name_"..workroom_id, teacher_id)
ssdb:hset("workroom_workrooms", workroom_id, cjson.encode(workroom))
ssdb:zdel("workroom_teachers_sorted_by_name_"..workroom_id.."_"..person.stage_id.."_"..person.subject_id, teacher_id)
ssdb:zdel("workroom_teachers_sorted_by_name_"..workroom_id.."_0_0", teacher_id)
ssdb:zdel("workroom_teachers_sorted_by_name_"..workroom_id.."_"..person.stage_id.."_0", teacher_id)
ssdb:zdel("workroom_"..workroom.level.."_t_new", teacher_id)
ssdb:zdel("workroom_0_t_new", teacher_id)
ssdb:zdel("workroom_0_t_hot", teacher_id)
ssdb:zdel("workroom_"..workroom.level.."_t_hot", teacher_id)
--该工作室的名师数-1
ssdb:hincr("workroom_tj_"..workroom_id,"teacher_count",-1)
--更新记录统计json的TS值
local tj_ts = math.random(1000000)..os.time()
ssdb:set("workroom_tj_ts_"..workroom_id,tj_ts)
ssdb:commit_pipeline()
ssdb:cancel_pipeline()

--陈续刚 于 2015.05.25添加，往mysql表写名师数据开始
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

local delete_Sql = "delete from t_base_workroom_member where wr_id="..workroom_id.." and leader_id="..person_id.." and user_type = 1";
db:query(delete_Sql);


--陈续刚 于 2015.05.25添加，往mysql表写名师数据结束

--陈续刚 2015.08.14添加，修改名师工作室的学段学科统计信息  开始
--全部学段全部学科
local update_sql1 = "update t_base_workroom_tj set teacher_count = teacher_count-1 where workroom_id="..workroom_id.." and stage_id=0 and subject_id=0";
db:query(update_sql1);

--学段全部学科
local update_sql2 = "update t_base_workroom_tj set teacher_count = teacher_count-1 where workroom_id="..workroom_id.." and stage_id="..person.stage_id.." and subject_id=0";
db:query(update_sql2);

--学段学科
local update_sql3 = "update t_base_workroom_tj set teacher_count = teacher_count-1 where workroom_id="..workroom_id.." and stage_id="..person.stage_id.." and subject_id=" ..person.subject_id.."";
db:query(update_sql3);

--陈续刚 2015.08.14添加，修改名师工作室的学段学科统计信息 结束


say("{\"success\":true,\"info\":\"删除成功！\"}")

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
ssdb:set_keepalive(0,v_pool_size)





