
local _whdjmhtj = {};

local function whdjmhtj(self, bureau_id,resource_id_int)
	--连接SSDB
	local ssdb = require "resty.ssdb"
	local ssdb_db = ssdb:new()
	local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
	if not ok then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end
	
	--连接mysql数据库
	local mysql = require "resty.mysql"
	local mysql_db = mysql:new()
	mysql_db:connect{
		host = v_mysql_ip,
		port = v_mysql_port,
		database = v_mysql_database,
		user = v_mysql_user,
		password = v_mysql_password,
		max_packet_size = 1024*1024
	}
	
	--将bureau_id下的资源总数-1
	ssdb_db:decr("djmh_rescount_"..bureau_id)	
	
	local resource_size_int = mysql_db:query("SELECT IFNULL(resource_size_int,0) AS resource_size_int FROM t_resource_info WHERE resource_id_int="..resource_id_int.." LIMIT 1")
	if #resource_size_int ~= 0 then
		local resource_size = tonumber(resource_size_int[1]["resource_size_int"])		
		ssdb_db:decr("djmh_ressize_"..bureau_id,resource_size)
	end
	
	--放回连接池
	mysql_db:set_keepalive(0,v_pool_size)
	ssdb_db:set_keepalive(0,v_pool_size)

end

_whdjmhtj.whdjmhtj = whdjmhtj;

return _whdjmhtj;

