--[[
@Author cuijinlong
@date 2015-4-10
--]]
--定义函数
local say = ngx.say
local len = string.len
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

--接收前台传来参数
local game_id = args["game_id"]
local student_id = ngx.var.cookie_person_id
local game_pass_test = args["game_pass_test"]
local class_id
local student
if not game_id or len(game_id) == 0 
			or not game_pass_test or len(game_pass_test) == 0  then
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

--通过当前学生的student_id获得class_id
local studente_vo = ngx.location.capture("/dsideal_yy/base/getStudentInfoByStudent_id",{
	body="student_id="..student_id
})
if studente_vo.status == 200 then
	student = cjson.decode(studente_vo.body).list
else
	say("{\"success\":false,\"info\":\"查询学生失败！\"}")
	return
end

if student then
	class_id = student[1].CLASS_ID
else
	say("{\"success\":false,\"info\":\"通过学生获得班级失败！\"}")
	return
end

--判断这个学生之前是否玩过此游戏，如果没玩过，那么系统记录本次通关数，如果玩过此游戏，那么看本次通过记录是不是最高分，如果高于之前的最佳成绩，那么记录本次通过数，否则不记录
local pass_test = 0
local is_oparate = 1 --默认将通过数记录到缓存
local stu_pass_num = ssdb:zget("student_game_"..class_id.."_"..game_id,student_id)
if tonumber(stu_pass_num[1]) then
	if tonumber(game_pass_test) > tonumber(stu_pass_num[1]) then
		pass_test = game_pass_test
	else
		pass_test = stu_pass_num[1]
		is_oparate = 0 --由于学生玩过游戏，并且本次不是最高通关数，所以不记录缓存
	end
else
	pass_test = game_pass_test
end

ssdb:set("last_pass_test_"..student_id.."_"..game_id,pass_test);--最后一次玩到第几关。
if is_oparate == 1 then
	local setok,err = ssdb:zset("student_game_"..class_id.."_"..game_id,student_id,pass_test)
	if not setok then
		say("{\"success\":false,\"info\":\"保持学生排名报错了！\"}")
	end
end
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)