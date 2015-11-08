--[[
维护系统标题
@Author  chenxg
@Date    2015-03-02
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
--参数 
local name = args["name"]
local stuname = args["stuname"]
local copyright = args["copyright"]
local otype = args["type"]
--local description = args["description"]

-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

--判断参数是否为空
--[[if not name or string.len(name) == 0 
or not stuname or string.len(stuname) == 0
or not copyright or string.len(copyright) == 0
or not otype or string.len(otype) == 0
  then
    say("{\"success\":false,\"info\":\"name or type 参数错误！\"}")
    return
end
]]
if otype == "1" then
	local insertSql = "delete from t_sys_config where id=2;insert into t_sys_config (id,name,stuname,copyright)values(2,"..quote(name)..","..quote(stuname)..","..quote(copyright)..")";		
	local ok, err = db:query(insertSql)
	if ok then
		cache:hmset("system_info","id",2,"name",name,"stuname",stuname,"copyright",copyright)
	end
	say("{\"success\":true}")
else
	local sysname = cache:hget("system_info","name");
	if sysname == ngx.null then 
		local insertSql = "select name,stuname,copyright from t_sys_config where id=2;";		
		local results, err = db:query(insertSql)
		if ok then
			cache:hmset("system_info","id",2,"name",results[1]["name"],"stuname",results[1]["stuname"],"copyright",results[1]["copyright"])
		end
	end
	sysname = cache:hget("system_info","name");
	stuname = cache:hget("system_info","stuname");
	copyright = cache:hget("system_info","copyright");
	--say(type(sysname))
	say("{\"success\":true,\"name\":\""..sysname.."\",\"stuname\":\""..stuname.."\",\"copyright\":\""..copyright.."\"}")
end
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
