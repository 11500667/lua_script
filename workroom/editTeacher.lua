--[[
编辑名师
@Author feiliming
@Date   2014-12-4
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

local teacher_id = args["teacher_id"]
local avatar_url = args["avatar_url"]
local description = args["description"]
local level = args["level"]
if not teacher_id or string.len(teacher_id) == 0 or not avatar_url or not description or not level or string.len(level) == 0 then
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

--查
local res, err = ssdb:hget("workroom_teachers", teacher_id)
if not res or string.len(res[1]) == 0 then
    say("{\"success\":false,\"info\":\"名师不存在！\"}")
    return
end

--description = ngx.encode_base64(description)
local teacher = cjson.decode(res[1])
teacher.avatar_url = avatar_url
teacher.description = description
teacher.level = level

--存
local ok, err = ssdb:hset("workroom_teachers", teacher_id, cjson.encode(teacher))
if not ok then
    say("{\"success\":false,\"info\":\"保存失败！\"}")
    return
end	

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

local update_Sql = "update t_base_workroom_member set level = "..quote(level)..",pic_url = "..quote(avatar_url)..",description = "..quote(description).." where leader_id="..quote(teacher.person_id).." and user_type = 1";
db:query(update_Sql);

--mysql放回连接池
db:set_keepalive(0, v_pool_size)

--陈续刚 于 2015.05.25添加，往mysql表写名师数据结束

say("{\"success\":true,\"info\":\"保存成功！\"}")

ssdb:set_keepalive(0,v_pool_size)