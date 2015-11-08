--[[
	局部函数：获取数据库连接
]]
local _DB = {};
---------------------------------------------------------------------------
function _DB:getMysqlDb()
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
		ngx.print("{\"success\":false,\"info\":\"查询数据失败！\"}")
		ngx.log(ngx.ERR, "=====> 连接数据库失败!");
		return false;
	end
	
	return db;
end
---------------------------------------------------------------------------
--[[
	局部函数：创建SSDB连接
]]
function _DB:getSSDb()
	local ssdblib = require "resty.ssdb"
	local ssdb = ssdblib:new()
	local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
	if not ok then
		say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end
	return ssdb;
end
---------------------------------------------------------------------------
--[[
	局部函数：将ssdb连接归还到连接池
]]
function _DB:keepSSDbAlive(ssdb)
	ok, err = ssdb:set_keepalive(0,v_pool_size)
	if not ok then
		ngx.log(ngx.ERR, "====>将SSDB数据库连接归还连接池出错！");
		return false;
	end
	return true;
end
---------------------------------------------------------------------------
--[[
	局部函数：将mysql连接归还到连接池
]]
function _DB:keepMysqlDbAlive(db)
	ok, err = db: set_keepalive(0, v_pool_size);
	if not ok then
		ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
		return false;
	end
	return true;
end

---------------------------------------------------------------------------
-- _DBUtil.getDb = getDb;
-- _DBUtil.keepDbAlive = keepDbAlive;

-- 返回DBUtil对象
return _DB;