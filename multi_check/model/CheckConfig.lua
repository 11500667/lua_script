--[[
#申健 2015-03-12
#描述：审核设置的基础函数类
]]


local _CheckConfig = {};

---------------------------------------------------------------------------
--[[
	局部函数： 根据ID获取审核记录
	作者：     申健 2015-03-08
	参数：     checkId  	审核记录的ID
	返回值1：  boolean 查询是否成功
	返回值2：  审核记录的table
]]
local function getConfig(self, unitId)
	
	--连接SSDB
	local ssdblib = require "resty.ssdb"
	local ssdb = ssdblib:new()
	local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port) 
	if not ok then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end

	ngx.log(ngx.ERR, "<===> 获取审核设置：单位ID->[" .. unitId .. "] <===>");

	-- 1.判断ssdb中是否存在该机构的审核机制
	local isExistTab = ssdb:hexists("check_config_" .. unitId, "auto_pass");
	local isExist    = tonumber(isExistTab[1]);
	ngx.log(ngx.ERR, "===> SSDB KEY: [check_config_", unitId, "], 是否存在：[", ((isExist==1 and "存在") or "不存在"), "]");

	-- 1-1 如果该单位的配置存在
	if isExist == 1 then
		local configInfo, err = ssdb:multi_hget("check_config_" .. unitId, "auto_pass", "check_way", "force_check");
		ngx.log(ngx.ERR, "=== configInfo ==>", type(configInfo), #configInfo, configInfo[1], type(configInfo[1]));
		local autoPass   = tonumber(configInfo[2]);
		local checkWay   = tonumber(configInfo[4]);
		local forceCheck = tonumber(configInfo[6]);
		ngx.log(ngx.ERR, "===> 自动通过: [", autoPass, "], 审核模式: [", checkWay, "], 强制审核: [", forceCheck, "] <=== ");
		return autoPass, checkWay, forceCheck;
	else
		ssdb:multi_hset(
			"check_config_" .. unitId,
			"auto_pass"		, "1",
			"check_way"		, "1",
			"force_check"	, "1"
		);
		return 1,1,1;
	end
end

_CheckConfig.getConfig = getConfig;

---------------------------------------------------------------------------

return _CheckConfig;

