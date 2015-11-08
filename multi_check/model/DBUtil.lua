--[[
	局部函数：获取数据库连接
]]
local _DBUtil = {};

---------------------------------------------------------------------------
function _DBUtil:getDb()
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
	局部函数：将mysql连接归还到连接池
]]
function _DBUtil:keepDbAlive(db)
	ok, err = db: set_keepalive(0, v_pool_size);
	if not ok then
		ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
		return false;
	end
	return true;
end

---------------------------------------------------------------------------
--[[
	局部函数：批量向mysql中插入数据
	参数：sqlTable 	 记录sql语句的table
	参数：pSize   	 每批次批量提交的条数
]]
function _DBUtil:batchExecuteSqlInTx(sqlTable, pSize)
	local sql = "START TRANSACTION;";
	if sqlTable~=nil and #sqlTable > 0 then
		
		local db = _DBUtil: getDb();
		
		ngx.log(ngx.ERR, " ===> 批量执行sql语句 ===> ");
		local batchFlag = 0;
		for i=1, #sqlTable do
			
			sql = sql .. sqlTable[i];
			batchFlag = batchFlag + 1;
			
			ngx.log(ngx.ERR, " ===> 第", i , "条SQL语句 ===> ", sqlTable[i]);
			if batchFlag == pSize or i==#sqlTable then 
				sql = sql .. "COMMIT;";
				ngx.log(ngx.ERR, " ===> 批量提交的SQL语句 ===> ", sql);
				local res, err, errno, sqlstate = db:query(sql)
				if not res then
					ngx.log(ngx.ERR, "sql执行出错， 错误信息：err -> [", err, "], errno -> [", errno, "], sqlstate -> [", sqlstate, "].");
					return false;
				end

				-- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
				while err == "again" do
					res, err, errno, sqlstate = db:read_result()
					if not res then
						ngx.log(ngx.ERR, "sql执行出错， 错误信息：err -> [", err, "], errno -> [", errno, "], sqlstate -> [", sqlstate, "].");
						return false;
					end
				end
				
				batchFlag = 0;
				sql = "START TRANSACTION;";
			end
		end
		-- 将数据库连接返回连接池
		_DBUtil: keepDbAlive(db);
	end
	return true;
	
end

---------------------------------------------------------------------------
-- _DBUtil.getDb = getDb;
-- _DBUtil.keepDbAlive = keepDbAlive;

-- 返回DBUtil对象
return _DBUtil;