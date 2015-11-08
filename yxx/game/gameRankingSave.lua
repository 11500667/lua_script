--[[
@Author cuijinlong
@date 2015-4-10
--]]
--���庯��
local say = ngx.say
local len = string.len
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--�ж�request����, ����������
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

--����ǰ̨��������
local game_id = args["game_id"]
local student_id = ngx.var.cookie_person_id
local game_pass_test = args["game_pass_test"]
local class_id
local student
if not game_id or len(game_id) == 0 
			or not game_pass_test or len(game_pass_test) == 0  then
    say("{\"success\":false,\"info\":\"��������\"}")
    return
end

--����ssdb����
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--ͨ����ǰѧ����student_id���class_id
local studente_vo = ngx.location.capture("/dsideal_yy/base/getStudentInfoByStudent_id",{
	body="student_id="..student_id
})
if studente_vo.status == 200 then
	student = cjson.decode(studente_vo.body).list
else
	say("{\"success\":false,\"info\":\"��ѯѧ��ʧ�ܣ�\"}")
	return
end

if student then
	class_id = student[1].CLASS_ID
else
	say("{\"success\":false,\"info\":\"ͨ��ѧ����ð༶ʧ�ܣ�\"}")
	return
end

--�ж����ѧ��֮ǰ�Ƿ��������Ϸ�����û�������ôϵͳ��¼����ͨ����������������Ϸ����ô������ͨ����¼�ǲ�����߷֣��������֮ǰ����ѳɼ�����ô��¼����ͨ���������򲻼�¼
local pass_test = 0
local is_oparate = 1 --Ĭ�Ͻ�ͨ������¼������
local stu_pass_num = ssdb:zget("student_game_"..class_id.."_"..game_id,student_id)
if tonumber(stu_pass_num[1]) then
	if tonumber(game_pass_test) > tonumber(stu_pass_num[1]) then
		pass_test = game_pass_test
	else
		pass_test = stu_pass_num[1]
		is_oparate = 0 --����ѧ�������Ϸ�����ұ��β������ͨ���������Բ���¼����
	end
else
	pass_test = game_pass_test
end

ssdb:set("last_pass_test_"..student_id.."_"..game_id,pass_test);--���һ���浽�ڼ��ء�
if is_oparate == 1 then
	local setok,err = ssdb:zset("student_game_"..class_id.."_"..game_id,student_id,pass_test)
	if not setok then
		say("{\"success\":false,\"info\":\"����ѧ�����������ˣ�\"}")
	end
end
--ssdb�Ż����ӳ�
ssdb:set_keepalive(0,v_pool_size)