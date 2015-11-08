--[[
获取工作室成员列表
@Author  chenxg
@Date    2015-05-23
--]]

local say = ngx.say

--引用模块
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
local wr_id = args["wr_id"]
local leader_id = args["leader_id"]
if not wr_id or string.len(wr_id) == 0 
	or not leader_id or string.len(leader_id) == 0 
	  then
		say("{\"success\":false,\"info\":\"wr_id or leader_id 参数错误！\"}")
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
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

local returnjson = {}

local person_Sql = "select person_id,person_name,pic_url as img_url from t_base_workroom_member wm left join t_base_person p on p.person_id = wm.member_id where wm.wr_id ="..wr_id.." and leader_id="..leader_id.." and user_type=2 ";

local person_list, err, errno, sqlstate = db:query(person_Sql);
	ngx.log(ngx.ERR, "cxg_log =====>"..person_Sql);
if not person_list then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local sch_res_list = {}
for i=1,#person_list do
	local res_list = {}
	res_list.person_id = person_list[i]["person_id"]
	res_list.person_name = person_list[i]["person_name"]
	res_list.img_url = person_list[i]["img_url"]
	sch_res_list[i] = res_list
end

returnjson.person_list = sch_res_list
returnjson.success = true
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
