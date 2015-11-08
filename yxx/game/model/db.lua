--[[
	�ֲ���������ȡ���ݿ�����
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
		ngx.print("{\"success\":false,\"info\":\"��ѯ����ʧ�ܣ�\"}")
		ngx.log(ngx.ERR, "=====> �������ݿ�ʧ��!");
		return false;
	end
	
	return db;
end
---------------------------------------------------------------------------
--[[
	�ֲ�����������SSDB����
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
	�ֲ���������ssdb���ӹ黹�����ӳ�
]]
function _DB:keepSSDbAlive(ssdb)
	ok, err = ssdb:set_keepalive(0,v_pool_size)
	if not ok then
		ngx.log(ngx.ERR, "====>��SSDB���ݿ����ӹ黹���ӳس���");
		return false;
	end
	return true;
end
---------------------------------------------------------------------------
--[[
	�ֲ���������mysql���ӹ黹�����ӳ�
]]
function _DB:keepMysqlDbAlive(db)
	ok, err = db: set_keepalive(0, v_pool_size);
	if not ok then
		ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
		return false;
	end
	return true;
end

---------------------------------------------------------------------------
-- _DBUtil.getDb = getDb;
-- _DBUtil.keepDbAlive = keepDbAlive;

-- ����DBUtil����
return _DB;