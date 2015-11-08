-- 1. 获取cookie的参数
local personId = tostring(ngx.var.cookie_background_person_id);
local identityId = tostring(ngx.var.cookie_background_identity_id);

-- 2. 获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["check_id"] == nil or args["check_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数check_id不能为空！\"}");
	return;
elseif args["unit_code"] == nil or args["unit_code"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数unit_code不能为空！\"}");
	return;
elseif args["unit_id"] == nil or args["unit_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数unit_id不能为空！\"}");
	return;
end

local checkId  = tostring(args["check_id"]);
local unitId   = tostring(args["unit_id"]);
local unitCode = tostring(args["unit_code"]);

-- 3. 获取数据库连接
local function getDb()
	
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
		return false;
	end
	
	return db;
end

local function getCache()
	-- 4.获取redis链接
	local redis = require "resty.redis"
	local cache = redis:new()
	local ok,err = cache:connect(v_redis_ip,v_redis_port)
	if not ok then
		ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
		return false;
	end
	
	return cache;
end

local db = getDb();
if not db then
	return;
end;

local cache = getCache();
if not cache then
	return;
end;

-- 如果审核记录没有上锁，则锁住审核记录5分钟，在此5分钟内，其他人不允许审核该记录。
local isExist = cache:exists("check_" .. checkId .. "_" .. unitCode);
if isExist == 0 then
	cache:hmset("check_" .. checkId .. "_" .. unitCode, "person_id", personId, "identity_id", identityId);
	cache:expire("check_" .. checkId .. "_" .. unitCode, 300);
end

ngx.say("{\"success\":\"true\"}");

-- local isExist = cache:exists("check_" .. checkId);
-- if isExist == 1 then
	-- local result = cache:hmget("check_" .. checkId, "person_id", "identity_id");
	-- local tempPersonId   = result[1];
	-- local tempIdentityId = result[2];
	-- if personId==tempPersonId and identityId==tempIdentityId then
		-- ngx.say("{\"success\":\"true\",\"isChecking\":false}");
		-- return;
	-- else
		-- ngx.say("{\"success\":\"true\",\"isChecking\":true}");
		-- return;
	-- end
	
-- else
	-- cache:hmset("check_" .. checkId, "person_id", personId, "identity_id", identityId);
	-- cache:expire("check_" .. checkId, 600);
	-- ngx.say("{\"success\":\"true\",\"isChecking\":false}");
	-- return;
-- end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end



