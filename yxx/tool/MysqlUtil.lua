--[[
	局部函数：获取数据库连接
]]
local _MysqlUtil = {};
local mysql = require "resty.mysql";
---------------------------------------------------------------------------
function _MysqlUtil:getDb()

    -- 放入连接池当前缓存对象
    --[[
     https://github.com/openresty/lua-resty-redis#connect 这里面的说明。把链接放到ngx.ctx中，是以便一次请求中，多次访问redis。而不是用来处理连接池(是否新建一个连接，还是复用链接)的，这个不需要我们自己处理。
]]

    if ngx.ctx.mysql_pool then
        return  ngx.ctx.mysql_pool
    end
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

    -- 获取到的数据库实例对象放入到缓存对象中
    ngx.ctx.mysql_pool = db;
    return ngx.ctx.mysql_pool;
end

---------------------------------------------------------------------------
--[[
	局部函数：将mysql连接归还到连接池
]]
function _MysqlUtil:close(db)

    if ngx.ctx.mysql_pool then
        ok,err = ngx.ctx.mysql_pool:set_keepalive(60000, 100)
        if not ok then
            ngx.log(ngx.ERR,"====>将Mysql数据库连接归还连接池出错！");
            return false;
        end
        ngx.ctx.mysql_pool = nil
    end
    return true;
end

------------------------------------------------------------------
--[[
	函数说明： 	查询单个sql
	参数：sql 	查询的sql语句
]]
function _MysqlUtil:query(sql)
    local db = _MysqlUtil:getDb();
    local res, err, errno, sqlstate  = db: query(sql);

    if not res  then
        ngx.log(ngx.ERR, "query db error. res: " .. (res or "nil"))
        return nil;
    end
    return res;
end

--[[
	函数说明： 	查询单个sql
	参数：sql 	查询的sql语句
]]
function _MysqlUtil:querySingleSql(sql)
    local db = _MysqlUtil:getDb();
    local queryResult, err, errno, sqlstate = db: query(sql);
    if not queryResult or queryResult == nil then
        ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
        _MysqlUtil:keepDbAlive(db);
        return false, err;
    end
    _MysqlUtil:keepDbAlive(db);
    return queryResult;
end

function _MysqlUtil:keepDbAlive(db)
    ok, err = db: set_keepalive(600000, v_pool_size);
    if not ok then
        ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 将Mysql数据库连接归还连接池出错！");
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
function _MysqlUtil:batch(sqlTable, pSize)
    local sql = "START TRANSACTION;";
    if sqlTable~=nil and #sqlTable > 0 then

        local db = _MysqlUtil: getDb();

        local batchFlag = 0;
        for i=1, #sqlTable do

            sql = sql .. sqlTable[i];
            batchFlag = batchFlag + 1;

            if batchFlag == pSize or i==#sqlTable then
                sql = sql .. "COMMIT;";
                local res, err, errno, sqlstate = db:query(sql)
                if not res then
                    return false;
                end
                -- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
                while err == "again" do
                    res, err, errno, sqlstate = db:read_result()
                    if not res then
                        return false;
                    end
                end
                batchFlag = 0;
                sql = "START TRANSACTION;";
            end
        end
    end
    return true;

end

---------------------------------------------------------------------------

-- 返回MysqlUtil对象
return _MysqlUtil;
