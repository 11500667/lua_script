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

--创建ssdb连接
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
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--获取当前用户所相关的协作体（所属和所管理，不包含大学区负责人）======================
local list1 = {}


--查询已发布
local xztsql = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=obj_id_int,"..obj_id_int..";filter=pub_type,3;filter=b_delete,0;!range=hd_id,0,999999;groupby=attr:xzt_id;'"

local hdsql = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=obj_id_int,"..obj_id_int..";filter=pub_type,3;range=hd_id,0,999999;filter=b_delete,0;groupby=attr:hd_id;'"
ngx.log(ngx.ERR,"===ssss=>"..xztsql.."<====")
local xztresult, err = db:query(xztsql)
if not xztresult then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
local xzt_names=""
local hd_names=""
for i=1,#xztresult do
	local  xztid = cache:hget("publish_"..xztresult[i]["id"],"xzt_id");
	ngx.log(ngx.ERR,"====>"..xztid.."<====")
	local hxzt = ssdb:hget("qyjh_xzt",xztid)
	local xzt = cjson.decode(hxzt[1])
	if xzt then
		xzt_names = xzt_names..xzt.name
	end
	if i ~= #xztresult then
		xzt_names = xzt_names..","
	end
end
--========
local hdresult, err = db:query(hdsql)
if not hdresult then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

for i=1,#hdresult do
	local  hdid = cache:hget("publish_"..hdresult[i]["id"],"hd_id");
	local hhd = ssdb:hget("qyjh_hd",hdid)
	local hd = cjson.decode(hhd[1])
	if hd then
		hd_names = hd_names..hd.active_name
	end
	if i ~= #hdresult then
		hd_names = hd_names..","
	end
end

returnjson.xzt_name = xzt_names
returnjson.hd_name = hd_names
returnjson.success = "true"
say(cjson.encode(returnjson))


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
