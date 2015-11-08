--[[
将ssdb存储的名师数据初始化到mysql表中
@Author 陈续刚
@Date   2015-05-25
--]]

local say = ngx.say
local len = string.len
local gsub = string.gsub
local quote = ngx.quote_sql_str

local cjson = require "cjson"

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

--获得get请求参数
local workroom_id = args["workroom_id"]

if not workroom_id or len(workroom_id)==0 then
	say("{\"success\":false,\"info\":\"workroom_id 参数错误！\"}")
	return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
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
	max_packet_size = 1024 * 1024 
}

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	return
end

local res, err = ssdb:zrange("workroom_teachers_sorted_by_name_"..workroom_id, 0, 100000)
if not res then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

local t_len = #res
local teacherids = {}
for i=1,t_len,2 do
	teacherids[#teacherids+1] = res[i]
end
--先删除mysql表中该工作室下的所有成员
local delete_Sql = "delete from  t_base_workroom_member where user_type=1 and wr_id = "..workroom_id;
db:query(delete_Sql);

--重新写入名师数据
local teachers, err = ssdb:multi_hget("workroom_teachers", unpack(teacherids))
if #teachers>=2 then
	for i=1,#teachers,2 do
		local teacher = cjson.decode(teachers[i+1])
		local id = teacher.teacher_id
		local leader_id = teacher.person_id
		local level = teacher.level
		local avatar_url = teacher.avatar_url
		local description = teacher.description
		
		local insert_Sql = "insert into t_base_workroom_member(id,wr_id,leader_id,level,user_type,pic_url,description) values("..quote(id)..","..quote(workroom_id)..","..quote(leader_id)..","..quote(level)..",1,"..quote(avatar_url)..","..quote(description)..")";
		db:query(insert_Sql);

	end
end
--初始化教师资源数据
local res_Sql = "UPDATE t_base_workroom_member t set t.res_count = (SELECT count(*) from t_base_publish p where p.pub_type = 1 and p.person_id = t.leader_id and p.b_delete = 0 and t.wr_id = p.pub_target) where wr_id = "..workroom_id;
db:query(res_Sql);

say("{\"success\":true,\"info\":\"保存成功！\"}")
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0, v_pool_size)
