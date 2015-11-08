--[[
根据当前用户获取资源发布范围
@Author  chenxg
@Date    2015-03-03
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
cjson.encode_empty_table_as_object(false);

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
--参数 
local obj_id_int = ngx.var.arg_obj_id_int
if not obj_id_int or string.len(obj_id_int) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

local returnjson = {}


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

--获取当前用户所相关的协作体（所属和所管理，不包含大学区负责人）======================
local list1 = {}

--查询已发布
local xzt_query_sql = "select xzt_name from t_qyjh_xzt where b_use=1 and xzt_id in (select xzt_id from t_base_publish where b_delete =0 and hd_id =-1 and obj_id_int = "..obj_id_int..")"
local xztresult, err = db:query(xzt_query_sql)

local hd_query_sql = "select hd_name as active_name from t_qyjh_hd where b_delete=1 and hd_id in (select hd_id from t_base_publish where b_delete =0 and hd_id !=-1 and obj_id_int = "..obj_id_int..")"

if not xztresult then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
local xzt_names=""
local hd_names=""
for i=1,#xztresult do
	xzt_names = xzt_names..xztresult[i]["xzt_name"]
	if i ~= #xztresult then
		xzt_names = xzt_names..","
	end
end
--========
local hdresult, err = db:query(hd_query_sql)
if not hdresult then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

for i=1,#hdresult do
		hd_names = hd_names..hdresult[i]["active_name"]
	if i ~= #hdresult then
		hd_names = hd_names..","
	end
end

returnjson.xzt_name = xzt_names
returnjson.hd_name = hd_names
returnjson.success = "true"
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
