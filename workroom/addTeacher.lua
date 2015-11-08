--[[
添加名师到工作室
@Author feiliming
@Date   2014-11-28
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local quote = ngx.quote_sql_str

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

local workroom_id = args["workroom_id"]
local person_id = args["person_id"]
local avatar_url = args["avatar_url"]
local description = args["description"]
--名师级别 1区 2市 3省 4国家
local level = args["level"]
if not workroom_id or string.len(workroom_id) == 0 or not person_id or string.len(person_id) == 0 or not avatar_url or not description or not level or string.len(level) == 0 then
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

--判断person_id是否已在工作室下
local workroom_person, err = ssdb:hget("workroom_workroom_person", workroom_id.."_"..person_id)
if string.len(workroom_person[1]) ~= 0 then
	say("{\"success\":false,\"info\":\"该用户已添加到此工作室！\"}")
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
	say("{\"success\":false,\"info\":\"保存失败！\"}")
    return
end
--获取person_name的区位码, 调用java接口
local person_name = person.person_name
local quwei
local res_quwei = ngx.location.capture("/getQuwei", {
	args = { person_name = person_name }
})
if res_quwei.status == 200 then
    quwei = cjson.decode(res_quwei.body)
else
	say("{\"success\":false,\"info\":\"保存失败！\"}")
    return
end

--取名师id
local teacher_id_t = ssdb:incr("workroom_teacher_pk")
local teacher_id = teacher_id_t[1]
--description = ngx.encode_base64(description)
--1
local teacher = {}
teacher.teacher_id = teacher_id
teacher.workroom_id = workroom_id
teacher.person_id = person_id
teacher.avatar_url = avatar_url
teacher.description = description
teacher.level = level
--3
local person_teacher_t = ssdb:hget("workroom_person_teacher", person_id)
local teacherids
if string.len(person_teacher_t[1]) == 0 then
	teacherids = teacher_id
else
	teacherids = person_teacher_t[1]..","..teacher_id
end
--5
local t_workroom, err = ssdb:hget("workroom_workrooms", workroom_id)
local workroom = cjson.decode(t_workroom[1])
local t_stage = workroom.stage
local stage_flag = false
local subject_flag = false
local subject_flag_0 = false
for i=1,#t_stage do
	--stage +1
	if tostring(t_stage[i].stage_id) == "0" then
		t_stage[i].teacher_num = t_stage[i].teacher_num + 1
		--subject +1
		local t_subject = t_stage[i].subject
		for j=1,#t_subject do
			if t_subject[j].subject_id == "0" then
				t_stage[i].subject[j].teacher_num = t_stage[i].subject[j].teacher_num + 1
			end
		end
	--stage +1
	elseif tostring(t_stage[i].stage_id) == tostring(person.stage_id) then
		stage_flag = true
		t_stage[i].teacher_num = t_stage[i].teacher_num + 1
		--subject +1
		local t_subject = t_stage[i].subject
		for j=1,#t_subject do
			if t_subject[j].subject_id == "0" then
				subject_flag_0 = true
				t_stage[i].subject[j].teacher_num = t_stage[i].subject[j].teacher_num + 1
			end
			if tostring(t_subject[j].subject_id) == tostring(person.subject_id) then
				subject_flag = true
				t_stage[i].subject[j].teacher_num = t_stage[i].subject[j].teacher_num + 1
			end
		end
		if not subject_flag_0 then
			local psubject = {}
			psubject = {
				subject_id = "0",
				subject_name = "全部",
				teacher_num = 1
			}
			local suffix = #t_subject + 1
			t_stage[i].subject[suffix] = psubject
		end
		t_subject = t_stage[i].subject			
		if not subject_flag then
			local psubject = {}
			psubject = {
				subject_id = person.subject_id,
				subject_name = person.subject_name,
				teacher_num = 1
			}
			local suffix = #t_subject + 1
			t_stage[i].subject[suffix] = psubject
		end	
	end
end
if not stage_flag then
	local subject = {}
	subject[1] = {
		subject_id = "0",
		subject_name = "全部",
		teacher_num = 1
	}	
	subject[2] = {
		subject_id = person.subject_id,
		subject_name = person.subject_name,
		teacher_num = 1
	}
	local stage = {}
	stage = {
		stage_id = person.stage_id,
		stage_name = person.stage_name,
		teacher_num = 1,
		subject = subject
	}
	local suffix = #t_stage + 1
	t_stage[suffix] = stage
end

workroom.stage = t_stage
--say(cjson.encode(workroom))

local ts = os.date("%Y%m%d%H%M%S")

--set:1名师, 2工作室和person多对多, 3person是否名师一对多, 
--4工作室下名师按姓排序, 5工作室学段学科, 678工作室学段学科下名师
--9名师区市省最新, 10名师最新
ssdb:init_pipeline()
ssdb:hset("workroom_teachers", teacher_id, cjson.encode(teacher))
ssdb:hset("workroom_workroom_person", workroom_id.."_"..person_id, "1")
ssdb:hset("workroom_person_teacher", person_id, teacherids)
ssdb:zset("workroom_teachers_sorted_by_name_"..workroom_id, teacher_id, quwei.quwei)
ssdb:hset("workroom_workrooms", workroom_id, cjson.encode(workroom))
ssdb:zset("workroom_teachers_sorted_by_name_"..workroom_id.."_"..person.stage_id.."_"..person.subject_id, teacher_id, quwei.quwei)
ssdb:zset("workroom_teachers_sorted_by_name_"..workroom_id.."_0_0", teacher_id, quwei.quwei)
ssdb:zset("workroom_teachers_sorted_by_name_"..workroom_id.."_"..person.stage_id.."_0", teacher_id, quwei.quwei)
ssdb:zset("workroom_"..workroom.level.."_t_new", teacher_id, ts)
ssdb:zset("workroom_0_t_new", teacher_id, ts)
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

local insert_Sql = "insert into t_base_workroom_member(id,wr_id,leader_id,level,user_type,pic_url,description) values("..teacher_id..","..quote(workroom_id)..","..quote(person_id)..","..quote(level)..",1,"..quote(avatar_url)..","..quote(description)..")";
--ngx.log(ngx.ERR, "insert_Sql =====> "..insert_Sql);
db:query(insert_Sql);

--陈续刚 于 2015.05.25添加，往mysql表写名师数据结束

--陈续刚 2015.08.14添加，将名师工作室的学段学科统计信息写入mysql表“t_base_workroom_tj” 中  开始


--全部学段全部学科
local all_stage_subject_sql = "select id from t_base_workroom_tj where workroom_id="..workroom_id.." and stage_id = 0 and subject_id=0"
local all_stage_subject_result = db:query(all_stage_subject_sql);
if all_stage_subject_result and #all_stage_subject_result>=1 then
	local update_sql1 = "update t_base_workroom_tj set teacher_count = teacher_count+1 where workroom_id="..workroom_id.." and stage_id=0 and subject_id=0";
	db:query(update_sql1);
else
	local insert_sql1 = "insert into t_base_workroom_tj(workroom_level,workroom_id,stage_id,subject_id,teacher_count) values("..workroom.level..","..workroom_id..",0,0,1)";
	db:query(insert_sql1);
end

--学段全部学科
local stage_all_subject_sql = "select id from t_base_workroom_tj where workroom_id="..workroom_id.." and stage_id = "..person.stage_id.." and subject_id=0"
local stage_all_subject_result = db:query(stage_all_subject_sql);
if stage_all_subject_result and #stage_all_subject_result>=1 then
	local update_sql2 = "update t_base_workroom_tj set teacher_count = teacher_count+1 where workroom_id="..workroom_id.." and stage_id="..person.stage_id.." and subject_id=0";
	db:query(update_sql2);
else
	local insert_sql2 = "insert into t_base_workroom_tj(workroom_level,workroom_id,stage_id,subject_id,teacher_count) values("..workroom.level..","..workroom_id..","..person.stage_id..",0,1)";
	db:query(insert_sql2);
end

--学段学科
local stage_subject_sql = "select id from t_base_workroom_tj where workroom_id="..workroom_id.." and stage_id = "..person.stage_id.." and subject_id="..person.subject_id..""
local stage_subject_result = db:query(stage_subject_sql);
if stage_subject_result and #stage_subject_result>=1 then
	local update_sql3 = "update t_base_workroom_tj set teacher_count = teacher_count+1 where workroom_id="..workroom_id.." and stage_id="..person.stage_id.." and subject_id=" ..person.subject_id.."";
	db:query(update_sql3);
else
	local insert_sql3 = "insert into t_base_workroom_tj(workroom_level,workroom_id,stage_id,subject_id,teacher_count) values("..workroom.level..","..workroom_id..","..person.stage_id..","..person.subject_id..",1)";
	db:query(insert_sql3);
end

--陈续刚 2015.08.14添加，将名师工作室的学段学科统计信息写入mysql表中 结束

say("{\"success\":true,\"info\":\"保存成功！\"}")
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)

