--[[
	局部函数：获取数据库连接
]]
local mysql   = require "resty.mysql";
local _DBUtil = {};

---------------------------------------------------------------------------
function _DBUtil:getDb()
	local db, err = mysql: new();
	if not db then 
		ngx.log(ngx.ERR, err);
		return;
	end

	db:set_timeout(15000) -- 1 sec

	local ok, err, errno, sqlstate = db:connect{
		host            = v_mysql_ip,
		port            = v_mysql_port,
		database        = v_mysql_database,
		user            = v_mysql_user,
		password        = v_mysql_password,
		max_packet_size = 1024 * 1024 }

	if not ok then
		ngx.print("{\"success\":false,\"info\":\"查询数据失败！\"}")
		ngx.log(ngx.ERR, "[sj_log] -> [DBUtil] -> 连接数据库失败!");
		return false;
	end
	
	return db;
end

---------------------------------------------------------------------------
--[[
	局部函数：将mysql连接归还到连接池
]]
function _DBUtil:keepDbAlive(db)
	ok, err = db: set_keepalive(600000, v_pool_size);
	if not ok then
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 将Mysql数据库连接归还连接池出错！");
		return false;
	end
	return true;
end

---------------------------------------------------------------------------
--[[
	函数说明： 	查询单个sql
	参数：sql 	查询的sql语句
]]
function _DBUtil:querySingleSql(sql)
	local db = _DBUtil:getDb();
	local queryResult, err, errno, sqlstate = db: query(sql);
    if not queryResult or queryResult == nil then
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql语句：[", sql, "], sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		_DBUtil:keepDbAlive(db);
		return false, err;
	end
	_DBUtil:keepDbAlive(db);
	return queryResult;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： DBUtil公有函数 -> 插入数据
-- 日    期： 2015年10月16日
-- 作    者： 申健
-- 参    数： tableName  要插入的表名
-- 参    数： dataTable  要插入的数据的table，存储类型为Hash类型
-- 返 回 值： string类型：需要调用的函数名；如果获取失败，则返回nil；
-- -----------------------------------------------------------------------------------
local function save(self, tableName, dataTable)
    
    ngx.log(ngx.ERR, "\n[sj_log] -> [DBUtil] -> save函数 -> \ntableName : [", tableName, "] \n dataTable: [", encodeJson(dataTable), "]\n");
    local columnSegement = "INSERT INTO " .. tableName ;
    local valueSegement  = "";
    local columnTable    = {};
    local valueTable     = {}; 

    for columnName, value in pairs(dataTable) do
        table.insert(columnTable , columnName);
        table.insert(valueTable  , value);
    end

    columnSegement = columnSegement .. " (" .. table.concat(columnTable , ", ") .. ")";
    valueSegement  = valueSegement  .. " (" .. table.concat(valueTable  , ", ") .. ");";

    local sql = columnSegement .. " VALUES" .. valueSegement;
    ngx.log(ngx.ERR, "[sj_log] -> [DBUtil] -> 组装后的sql如下：[", sql, "]");

    local db = self: getDb();
    local result, err, errno, sqlstate = db: query(sql);
    if not result then
        ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		self: keepDbAlive(db);
		return false, err;
    end
    self: keepDbAlive(db);
	return result;
end
_DBUtil.save = save;

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
		
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 批量执行sql语句 ===> ");
		local batchFlag = 0;
		for i=1, #sqlTable do
			
			sql = sql .. sqlTable[i];
			batchFlag = batchFlag + 1;
			
			ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 第", i , "条SQL语句 ===> ", sqlTable[i]);
			if batchFlag == pSize or i==#sqlTable then 
				sql = sql .. "COMMIT;";
				ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 批量提交的SQL语句 ===> ", sql);
				local res, err, errno, sqlstate = db:query(sql)
				if not res then
					ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql执行出错， 错误信息：err -> [", err, "], errno -> [", errno, "], sqlstate -> [", sqlstate, "].");
					return false;
				end

				-- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
				while err == "again" do
					res, err, errno, sqlstate = db:read_result()
					if not res then
						ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql执行出错， 错误信息：err -> [", err, "], errno -> [", errno, "], sqlstate -> [", sqlstate, "].");
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