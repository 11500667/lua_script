-- -----------------------------------------------------------------------------------
-- 文件描述： 异步队列的公用服务类
-- 日    期： 2015年10月12日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------
local redisUtil = require "common.CacheUtil";

local _AsyncQueService = {};

-- -----------------------------------------------------------------------------------
-- 函数描述： 向异步队列中写入信息
-- 日    期： 2015年10月12日
-- 参    数： cmdObj 命令信息: 支持table类型和string类型的变量
-- 返 回 值： 第一个返回值，类型：boolean，操作是否成功；
-- 返 回 值： 第二个返回值，类型：string，错误信息，如果操作成功，返回nil；
-- -----------------------------------------------------------------------------------
local function sendAsyncCmd(self, cmdObj)
	ngx.log(ngx.ERR, "\n\n[sj_log] -> [AsyncQueueService] -> type(cmdObj) -> [", type(cmdObj), "]\n\n");
    local cmdStr;
    if type(cmdObj) == "table" then
    	cmdStr = encodeJson(cmdObj);
    elseif type(cmdObj) == "string" then
    	cmdStr = cmdObj;
    else
    	return false, "调用sendAsyncCmd错误， 错误信息：参数cmdObj的值只能为table类型和string类型。";
    end
    local res, err = redisUtil: lpush("async_service_queue", cmdStr);
    if not res then
    	ngx.log(ngx.ERR, "\n\n[sj_log] -> [AsyncQueueService] -> 错误信息：[", err, "]\n\n");
    	return false, "调用sendAsyncCmd错误， 错误信息：向队列async_service_queue中写入信息出错。";
    end
    return true;
end
_AsyncQueService.sendAsyncCmd = sendAsyncCmd;

-- -----------------------------------------------------------------------------------
-- 函数描述： 获取异步队列的命令（字符串）
-- 日    期： 2015年10月12日
-- 参    数： serviceCode 服务编码
-- 参    数： paramObj    参数对象，table类型
-- 返 回 值： string对象
-- -----------------------------------------------------------------------------------
local function getAsyncCmd(self, serviceCode, paramObj)
    if serviceCode == nil or serviceCode == "" then
    	error("服务代码不能为nil或空字符串");
    end
    if paramObj == nil then
    	error("参数不能为空");
    end

    if type(paramObj) == "table" then
        paramObj = encodeJson(paramObj);
    end

    local cmdObj = {};
    cmdObj.service_code = serviceCode;
    cmdObj.paramstr     = paramObj;
    cmdObj.serial_num   = getTS();

    return encodeJson(cmdObj);
end
_AsyncQueService.getAsyncCmd = getAsyncCmd;


return _AsyncQueService;