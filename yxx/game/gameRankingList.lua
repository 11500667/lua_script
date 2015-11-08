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
local class_id
local student_list
if not game_id or len(game_id) == 0 then
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


local student
local studente_vo = ngx.location.capture("/dsideal_yy/base/getStudentInfoByStudent_id",{
	body="student_id="..student_id
})
if studente_vo.status == 200 then
	student = cjson.decode(studente_vo.body).list
else
	say("{\"success\":false,\"info\":\"��ѯ�༶��ѧ��ʧ�ܣ�\"}")
	return
end
if student then
	class_id = student[1].CLASS_ID
	--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@@@@@@@"..student[1].CLASS_ID.."@@@@@@@@@@@@@@@@@@@@")
end

--ͨ���༶id����Ϸid��øð༶ѧ��������Ϸ������
local game_ranking_list,err = ssdb:zrrange("student_game_"..class_id.."_"..game_id, 0, 100)
if not game_ranking_list then
	say("{\"success\":false,\"info\":\"��Ϸ������ѯ�����ˣ�\"}")
	return
end

--ͨ��sudent_ids�ӻ������ݻ��ѧ����Ϣ  �磺283,284,285 --ngx.log(ngx.ERR, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBB"..student_list)
local studentes = ngx.location.capture("/dsideal_yy/base/getStudentByClassId",{
	body="class_id="..class_id
})


if studentes.status == 200 then
	student_list = cjson.decode(studentes.body).list
else
	say("{\"success\":false,\"info\":\"��ѯ�༶��ѧ��ʧ�ܣ�\"}")
	return
end

local jsonData
if student_list then
	if student_list[1]~="ok" and game_ranking_list[1]~="ok" then
		local return_table={}
		local return_table_ranking_list={}
		local flag = 1
		return_table["success"] = true
		for j=1,#game_ranking_list,2 do
			for i=1,#student_list do
				local from_base_stu_id = student_list[i].student_id
				local from_bussines_stu_id = game_ranking_list[j]
				if(tostring(from_base_stu_id) == tostring(from_bussines_stu_id)) then
					local table_temp={}
					table_temp["student_name"]=student_list[i].student_name
					table_temp["student_id"]=game_ranking_list[j]
				    table_temp["game_ranking"]=game_ranking_list[j+1]
					return_table_ranking_list[flag]=table_temp
					flag = flag + 1
					break
				end
			end
		end
		return_table["ranking_list"] = return_table_ranking_list
		jsonData=cjson.encode(return_table)
		say(jsonData)
	else
		ngx.say("{\"success\":true,\"ranking_list\":[]}")
		return
	end
end
--ssdb�Ż����ӳ�
ssdb:set_keepalive(0,v_pool_size)















