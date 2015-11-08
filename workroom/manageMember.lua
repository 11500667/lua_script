--[[
维护工作室成员
@Author  chenxg
@Date    2015-05-23
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
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
local wr_id = args["wr_id"]
local leader_id = args["leader_id"]
local target = ngx.unescape_uri(args["list"])
if not wr_id or string.len(wr_id) == 0 
	or not leader_id or string.len(leader_id) == 0 
  then
	say("{\"success\":false,\"info\":\"wr_id or leader_id 参数错误！\"}")
	return
end
ngx.log(ngx.ERR, "cxg_log =====>"..type(target));


local t_target = cjson.decode(target)

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
	return
end

local delete_Sql = "delete from t_base_workroom_member where wr_id ="..wr_id.." and leader_id="..leader_id.." and user_type=2 ";
db:query(delete_Sql);

for i=1,#t_target do
	local member_id = t_target[i].person_id
	local img_url = t_target[i].img_url
	
	local insert_Sql = "insert into t_base_workroom_member(wr_id,leader_id,member_id,user_type,pic_url) values("..quote(wr_id)..","..quote(leader_id)..","..quote(member_id)..",2,"..quote(img_url)..")";
	db:query(insert_Sql);
end

local returnjson = {}

returnjson.success = true
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
