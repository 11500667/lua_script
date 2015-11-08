-- local ssdbUtil = require "multi_check.model.SSDBUtil";
-- ngx.print(tostring(ssdbUtil.autoKeepAlive) .. "<br>");

-- --ssdbUtil: setAutoKeepAlive(false);

-- local nextValue = ssdbUtil: incr("sj_queue");
-- ngx.print("nextValue -> " .. nextValue .. "<br>");

-- local newSsdb = ssdbUtil: newInstance(false);
-- ngx.print(tostring(newSsdb.autoKeepAlive) .. "<br>");

-- nextValue = newSsdb: incr("sj_queue");
-- ngx.print("nextValue -> " .. nextValue .. "<br>");


-- newSsdb: hset("sj_hash", "key1", "value1");

-- newSsdb: multi_hset("sj_hash", { key2 = "value2", key3 = "value3"});

-- local result = newSsdb: multi_hget("sj_hash", "key1", "key2", "key3");

-- for i,v in ipairs(result) do
-- 	ngx.print(i .. " -> " .. v .. "<br>");
-- end

-- local result2 = newSsdb: multi_hget_hash("sj_hash", "key1", "key2", "key3");

-- for k,v in pairs(result2) do
-- 	ngx.print(k .. " -> " .. v .. "<br>");
-- end

-- newSsdb: keepAlive();

-- ngx.header["Cookie"] = "a=1;b=1;c=2;"

-- ngx.print("aaaa");



-- local DBUtil = require "common.DBUtil";
-- local db = DBUtil: getDb();

-- -- db: query("START TRANSACTION;");

-- -- db: query("INSERT INTO dsideal_db.temp_redis_cmd (redis_cmd, run_time) VALUES ('redis_cmd', NOW()) ;");
-- -- db: query("INSERT INTO dsideal_db.temp_redis_cmd (redis_cmd, run_time) VALUES ('redis_cmd', NOW()) ;");

-- -- db: query("COMMIT;");

-- DBUtil: querySingleSql("START TRANSACTION;");

-- DBUtil: querySingleSql("INSERT INTO dsideal_db.temp_redis_cmd (redis_cmd, run_time) VALUES ('redis_cmd', NOW()) ;");
-- DBUtil: querySingleSql("INSERT INTO dsideal_db.temp_redis_cmd (redis_cmd, run_time) VALUES ('redis_cmd', NOW()) ;");

-- --DBUtil: querySingleSql("ROLLBACK;");

-- ngx.print("数据库事务测试");
-- function string.split(str, delimiter)
    -- if str==nil or str=='' or delimiter==nil then
        -- return nil
    -- end
    
    -- local result = {}
    -- for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        -- table.insert(result, match)
    -- end
    -- return result
-- end

-- local uriStr = ngx.var.uri;
-- ngx.log(ngx.ERR, "\nuriStr -> [", uriStr, "]\n");


-- local uriTable = string.split(uriStr, "/");

-- local lastSepIndex = string.find(uriStr, "/");
-- ngx.log(ngx.ERR, "\nlastUriStr -> [", uriTable[#uriTable], "]\n");

-- ngx.say(uriStr);
-- ngx.say("---->" .. uriTable[#uriTable]);  
local DBTxModel = require "common.DBTx";
local CacheUtil = require "common.CacheUtil";
local _TestController = {};

function _TestController: testUri2() 
    local paramValue1 = self: getParamByName("param1", true);
    local paramValue2 = self: getParamToNumber("param2");
    local paramValue3 = self: getParamToNumber("param3");
	
	local result = {};
	result.param1 = paramValue1;
	result.param2 = paramValue2;
	result.param3 = paramValue3;
	
	self: printJson(result);
end

function _TestController: testUri3()
	local dbTx = DBTxModel: new();

    ngx.log(ngx.ERR, "[sj_log] -> [DBTx] -> dbConn 是否为空: [", tostring(dbTx), "]");

    dbTx: query(" INSERT INTO temp_redis_cmd (redis_cmd, run_time) VALUES ('1111111111111111', NOW());");
    dbTx: query(" INSERT INTO temp_redis_cmd (redis_cmd, run_time) VALUES ('2222222222222222', NOW());");
    dbTx: rollback();

    self: printJson("ssssssssssssssssssssssssssssssss");
end

function _TestController: testMd5()
	local dbTx = DBTxModel: new();

    ngx.log(ngx.ERR, "[sj_log] -> [DBTx] -> dbConn 是否为空: [", ngx.md5("shenjian_test"), "]"); 
	self: printJson(ngx.md5("shenjian_test"));
    self: printJson("ssssssssssssssssssssssssssssssss");
end

function _TestController: testSSDB()

	local key = "sj_hash";

	CacheUtil: hmset(key, "key1", "val1", "key2", "val2");

	ngx.print(os.time());
end

BaseController: initController(_TestController);
