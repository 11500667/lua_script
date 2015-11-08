--[[
修改名师学段学科
@Author 陈续刚
@Date   2015.08.14
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
local subject_id = args["subject_id"]
local stage_id = args["stage_id"]
local workroom_id = args["workroom_id"]
if not teacher_id or string.len(teacher_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
ngx.log(ngx.ERR, "teacher_id =====> "..teacher_id.."subject_id =====> "..subject_id.."stage_id =====> "..stage_id.."workroom_id =====> "..workroom_id);
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
--教师相关数统计是否发生变化
local is_change = false
--陈续刚 于 2015.05.25添加，往mysql表写名师数据结束

--陈续刚 2015.08.14添加，修改名师工作室的学段学科统计信息  开始
local subject_sql = "select stage_id,su.subject_id from t_dm_subject su where su.subject_id in(select subject_id from t_base_person_subject where person_id="..teacher_id..")";
local old_subject = db:query(subject_sql);
if old_subject and #old_subject>=1 then
	is_change = true
	local  old_subject_id = old_subject[1]["subject_id"]
	local  old_stage_id = old_subject[1]["stage_id"]
	--学段全部学科
	local update_sql2 = "update t_base_workroom_tj set teacher_count = teacher_count-1 where workroom_id="..workroom_id.." and stage_id="..old_stage_id.." and subject_id=0";
	db:query(update_sql2);

	--学段学科
	local update_sql3 = "update t_base_workroom_tj set teacher_count = teacher_count-1 where workroom_id="..workroom_id.." and stage_id="..old_stage_id.." and subject_id=" ..old_subject_id.."";
	db:query(update_sql3);
else
	local insert_sql = "insert into t_base_person_subject(person_id,subject_id) values("..teacher_id..","..subject_id..")"
	db:query(insert_sql);
end

if is_change then
	--学段全部学科
	local stage_all_subject_sql = "select id from t_base_workroom_tj where workroom_id="..workroom_id.." and stage_id = "..stage_id.." and subject_id=0"
	local stage_all_subject_result = db:query(stage_all_subject_sql);
	if stage_all_subject_result and #stage_all_subject_result>=1 then
		local update_sql2 = "update t_base_workroom_tj set teacher_count = teacher_count+1 where workroom_id="..workroom_id.." and stage_id="..stage_id.." and subject_id=0";
		db:query(update_sql2);
	else
		local insert_sql2 = "insert into t_base_workroom_tj(workroom_level,workroom_id,stage_id,subject_id,teacher_count) values(1,"..workroom_id..","..stage_id..",0,1)";
		db:query(insert_sql2);
	end

	--学段学科
	local stage_subject_sql = "select id from t_base_workroom_tj where workroom_id="..workroom_id.." and stage_id = "..stage_id.." and subject_id="..subject_id..""
	local stage_subject_result = db:query(stage_subject_sql);
	if stage_subject_result and #stage_subject_result>=1 then
		local update_sql3 = "update t_base_workroom_tj set teacher_count = teacher_count+1 where workroom_id="..workroom_id.." and stage_id="..stage_id.." and subject_id=" ..subject_id.."";
		db:query(update_sql3);
	else
		local insert_sql3 = "insert into t_base_workroom_tj(workroom_level,workroom_id,stage_id,subject_id,teacher_count) values(1,"..workroom_id..","..stage_id..","..subject_id..",1)";
		db:query(insert_sql3);
	end
	local update_subject_sql = "update t_base_person_subject set subject_id = "..subject_id.." where person_id="..teacher_id..""
	db:query(update_subject_sql);

end
--陈续刚 2015.08.14添加，修改名师工作室的学段学科统计信息 结束

say("{\"success\":true,\"info\":\"修改成功！\"}")

--mysql放回连接池
db:set_keepalive(0, v_pool_size)





