--[[
TODO（发布时候调用，以后会改成登录用户所属联盟）
根据person_id查询所属联盟，同时判断资源id的发布状态，即已发布到哪几个联盟
@Author feiliming
@Date 2014-1-22
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

--TODO 查所属联盟, 现在查询所有
--zrange
local res = ssdb:zrange("league_leagues_sorted", 0, 100)
local lids = {}
if res and res[1] and res[1] ~= "ok" then
    for i=1,#res,2 do
        table.insert(lids, res[i])
    end
end

--multi_hget
local list = {}
local leagues = ssdb:multi_hget("league_leagues", unpack(lids))
for i=1,#leagues,2 do
    local league = cjson.decode(leagues[i+1])
    table.insert(list, league)
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
for i=1,#list do
	for j=1,#result do
		if list[i].league_id == tostring(result[j].pub_target) then
			list[i].publish = "1"
		end
	end
end

--返回值
local rr = {}
rr.success = true
rr.league_list = list

--return
say(cjson.encode(rr))

--放回连接池
ssdb:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)