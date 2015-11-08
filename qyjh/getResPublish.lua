--[[
根据person_id查询所属大学区、协作体，同时判断资源id的发布状态，即已发布到哪几个大学区、协作体
@Author chenxg	
@Date 2015-02-04
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
local qyjh_id = ngx.var.arg_qyjh_id
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
--***************************************************************
--查询所属和所管理的大学区
local dxqlist = {}
local dxq_list = {}
local paras = "?person_id="..person_id.."&qyjh_id="..qyjh_id
local res_dxq = ngx.location.capture("/dsideal_yy/ypt/qyjh/getDxqByPersonId"..paras)
if res_dxq.status == 200 then
	dxqlist = cjson.decode(res_dxq.body)
else
	say("{\"success\":false,\"info\":\"没有大学区！\"}")
	return
end
if #dxqlist.list>0 then
	for i = 1,#dxqlist.list,1 do
		local dxq_list2 = {}
		dxq_list2.dxq_id = dxqlist.list[i].dxq_id
		dxq_list2.name = dxqlist.list[i].name
		dxq_list2.publish = "0"
		dxq_list[#dxq_list+1] = dxq_list2
	end
end
--查询用户所属和所管理的协作体
local xztlist = {}
local xzt_list = {}
local paras = "?person_id="..person_id.."&qyjh_id="..qyjh_id
local res_xzt = ngx.location.capture("/dsideal_yy/ypt/qyjh/getXztByPersonId"..paras)
if res_dxq.status == 200 then
	xztlist = cjson.decode(res_xzt.body)
else
	say("{\"success\":false,\"info\":\"没有协作体！\"}")
	return
end
if #xztlist.list>0 then
	for i = 1,#xztlist.list,1 do
		local xzt_list2 = {}
		xzt_list2.xzt_id = xztlist.list[i].xzt_id
		xzt_list2.name = xztlist.list[i].name
		xzt_list2.publish = "0"
		xzt_list[#xzt_list+1] = xzt_list2
	end
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
for i=1,#dxq_list do
	for j=1,#result do
		if dxq_list[i].dxq_id == tostring(result[j].pub_target) then
			dxq_list[i].publish = "1"
		end
	end
end
--将已发布选中
for i=1,#xzt_list do
	for j=1,#result do
		if xzt_list[i].xzt_id == tostring(result[j].pub_target) then
			xzt_list[i].publish = "1"
		end
	end
end
--***************************************************************

--返回值
local returnjson = {}
returnjson.success = true
returnjson.xzt_list = xzt_list
returnjson.dxq_list = dxq_list

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
