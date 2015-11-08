-- -----------------------------------------------------------------------------------
-- 函数描述： 公有类 -> 数据库事务的工具类
-- 日    期： 2015年8月17日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------

local DBUtil = require "common.DBUtil";
_DBTx = { DBConn = nil, isTxStart = false, isTxCommit = false, isTxRollback = false };
local mt = { __index = _DBTx };

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 生成mysql事务处理的对象
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _DBTx: new()
    local dbConn = DBUtil: getDb();
    local tx = {
            DBConn       = dbConn, 
            isTxStart    = false, 
            isTxCommit   = false, 
            isTxRollback = false
        };
    setmetatable(tx, mt);

    tx: start();
    return tx;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 开始数据库事务
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _DBTx: start()
    if self.isTxStart then
        error("事务被重复开启");
    end
    local result, err, errno, sqlstate = self.DBConn: query("START TRANSACTION;");
    --ngx.log(ngx.ERR, "[sj_log] -> [DBTx] -> 开启事务结果： result: [", encodeJson(result), "], err:[", err, "], errno: [", errno, "], sqlstate: [", sqlstate, "]");
    self.isTxStart = true;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 销毁事务对象
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _DBTx: destory()
    DBUtil: keepDbAlive(self.DBConn);
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 在数据库事务中执行Sql语句
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _DBTx: query(sql)
    if not self.isTxStart then
		error("事务没有开启");
	end
	-- ngx.log(ngx.ERR, "[sj_log] -> [DBTx] -> self.isTxCommit: [", self.isTxCommit, "]");
	if self.isTxCommit then
		error("事务已经被提交，不能再执行sql语句");
	end
	
	if self.isTxRollback then
		error("事务已经回滚，不能再执行sql语句");
	end
	
	local result, err, errno, sqlState = self.DBConn: query(sql);
    -- ngx.log(ngx.ERR, "\n[sj_log] -> [DBTx] -> 事务中执行sql语句返回的结果： result: [", encodeJson(result), "], err:[", err, "], errno: [", errno, "], sqlstate: [", sqlstate, "]\n");
end


-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 提交事务
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _DBTx: commit()
    if isTxCommit then
        error("事务已经提交，不能再次提交！");
    end
    
    local result, err, errno, sqlState = self.DBConn: query("COMMIT;");
    --ngx.log(ngx.ERR, "[sj_log] -> [DBTx] -> 提交事务的返回结果： result: [", encodeJson(result), "], err:[", err, "], errno: [", errno, "], sqlstate: [", sqlstate, "]");
    if not result then
        error("提交事务出错， 错误信息:[" .. tostring(err) .. "]");
    end
    self.isTxCommit = true;
    DBUtil: keepDbAlive(self.DBConn);
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 回滚事务
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _DBTx: rollback()
    
	if isTxCommit then
		error("事务已经提交，不能进行回滚！");
	end
    
	if isTxRollback then
        error("事务已经回滚，不能多次回滚！");
    end
    
    local result, err, errno, sqlState = self.DBConn: query("ROLLBACK;");
    --ngx.log(ngx.ERR, "[sj_log] -> [DBTx] -> 回滚事务的返回结果： result: [", encodeJson(result), "], err:[", err, "], errno: [", errno, "], sqlstate: [", sqlstate, "]");
    if not res then
        error("回滚事务出错， 错误信息:[" .. tostring(err) .. "]");
    end
    self.isTxRollback = true;
    DBUtil: keepDbAlive(self.DBConn);
end

return _DBTx;