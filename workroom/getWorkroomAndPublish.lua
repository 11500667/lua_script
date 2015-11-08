--[[
根据person_id查询所属工作室，同时判断资源id的发布状态，即已发布到哪几个工作室
@Author feiliming
@Date 2014-12-24
--]]

local say = ngx.say
local len = string.len

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysql = require "resty.mysql"

--获得get请求参数
local person_id = ngx.var.arg_person_id
local pub_type = ngx.var.arg_pub_type
local obj_type = ngx.var.arg_obj_type
local obj_id_int = ngx.var.arg_obj_id_int
if not person_id or len(person_id) == 0
	or not pub_type or len(pub_type) == 0
	or not obj_type or len(obj_type) == 0
	or not obj_id_int or len(obj_id_int) == 0 then
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

--查所属工作室
local t_teacherids, err = ssdb:hget("workroom_person_teacher", person_id)

if not t_teacherids or len(t_teacherids[1]) < 1 then
	say("{\"success\":false,\"info\":\"未找到工作室！\"}")
	return
end

local workroom_list = {}
local a_teacherids = Split(t_teacherids[1], ",")
for i=1,#a_teacherids do
	local t_teacher, err = ssdb:hget("workroom_teachers", a_teacherids[i])
	local teacher = cjson.decode(t_teacher[1])
	local t_workroom = ssdb:hget("workroom_workrooms", teacher.workroom_id)
	local workroom = cjson.decode(t_workroom[1])
	local workroom2 = {}
	workroom2.workroom_id = workroom.workroom_id
	workroom2.name = workroom.name
	workroom2.publish = "0"
	workroom_list[#workroom_list+1] = workroom2
end

--连接mysql
local db, err = mysql:new()
if not db then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return	
end
local ok, err = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--查询已发布
local sql = "SELECT pub_target FROM t_base_publish p WHERE "..
	"p.person_id = "..person_id.." AND p.pub_type = "..pub_type.." "..
	"AND p.obj_type = "..obj_type.." AND p.obj_id_int = "..obj_id_int.." AND p.b_delete = 0"
local result, err = db:query(sql)
if not result then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
--将已发布选中
for i=1,#workroom_list do
	for j=1,#result do
		if workroom_list[i].workroom_id == tostring(result[j].pub_target) then
			workroom_list[i].publish = "1"
		end
	end
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.workroom_list = workroom_list

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
