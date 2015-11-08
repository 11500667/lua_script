--[[
将名师置顶
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
local teacher_id = args["teacher_id"]
local b_top = args["b_top"]

if not teacher_id or len(teacher_id)==0
 or not b_top or len(b_top)==0 then
	say("{\"success\":false,\"info\":\"teacher_id or b_top 参数错误！\"}")
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


local delete_Sql = "update t_base_workroom_member set b_top="..b_top.." where leader_id = "..teacher_id.." and user_type=1";
db:query(delete_Sql);

say("{\"success\":true,\"info\":\"保存成功！\"}")
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
