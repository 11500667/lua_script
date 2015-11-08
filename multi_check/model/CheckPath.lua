--[[
#申健 2015-03-12
#描述：审核状态的基础函数类
]]

local _CheckPath = {};

local mt = { __index = _CheckPath }


---------------------------------------------------------------------------
--[[
	描   述： 根据单位ID和审核路径获取该单位的审核状态
	作   者： 申健 2015-03-09
	参   数： unitType  		单位类型：1省、2市、3区、4总校、5分校
	参   数： checkPath  		审核路径
	返回值1： boolean 操作是否成功 true成功，false失败
	返回值2： 操作成功时返回单位的审核状态，操作失败时返回错误信息
]]
local function _getChkStatusByUnitId(unitId, checkPath)
	local CheckPerson = require "multi_check.model.CheckPerson";
	local unitType = CheckPerson:getUnitType(unitId);
	
	return _getChkStatusByUnitType(unitType, checkPath)
end

---------------------------------------------------------------------------
--[[
	局部函数：根据审核路径和单位类型获取该单位的状态
	作者：   申健 2015-03-09
	参数：   unitType  			单位类型：1省、2市、3区、4总校、5分校
	参数： 	 checkPath  		审核路径
	返回值1：boolean 			操作是否成功 true成功，false失败
	返回值2：操作成功时返回单位的审核状态，操作失败时返回错误信息
]]
local function _getChkStatusByUnitType(unitType, checkPath)
	if unitType == nil or type(unitType) ~= "number" then
		return false, "unitType的值不正确";
	end
	
	if #checkPath ~= 10 or type(checkPath) ~= "string" then
		return false, "checkPath的值不合法";
	end
	--[[
		截取字符串规律：
		     类型   开始截取位置      结束位置
		省：  1         1                2
		市：  2         3                4
		区：  3         5                6
		校：  4         7                8
		分校：5         9                10
		            (unitType*2)-1     unitType*2
	]]
	local chkStatus = string.sub(checkPath, (unitType*2)-1, unitType*2);
	return true, chkStatus;	
end


---------------------------------------------------------------------------
--[[
	局部函数：用于生成CheckPath对象
	作者：   申健 2015-03-13
	参数：   unitId  			单位ID
	参数： 	 checkPath  		审核路径
	返回值： CheckPath类对象
]]
function _CheckPath.new(self, unitId, checkPath)
    local CheckPerson = require "multi_check.model.CheckPerson";
	local unitType = CheckPerson:getUnitType(unitId);
	-- ngx.log(ngx.ERR, "===> _CheckPath.new 参数：unitId : ", unitId, ", type: ", type(unitId), " <===");
	-- ngx.log(ngx.ERR, "===> _CheckPath.new 参数：checkPath : ", checkPath, ", type: ", type(checkPath), " <===");
	local statusTab = {};
	for level=1, 5 do
		local result, checkStatus = _getChkStatusByUnitType(level, checkPath);
		-- ngx.log(ngx.ERR, "===> _CheckPath.new level ", level, ", checkStatus: ", checkStatus, ", type: ", type(checkPath), " <===");
		statusTab[level] = checkStatus;
	end
	
	return setmetatable({ 
		_unit_id 		= unitId, 
		_check_path 	= checkPath,
		_dest_level 	= 0,
		_curr_level 	= unitType,
		_status_table   = statusTab
	}, mt);
end

---------------------------------------------------------------------------
--[[
	局部函数：用于生成CheckPath对象
	作者：   申健 2015-04-10
	参数：   unitId  			单位ID
	参数： 	 checkPath  		审核路径
	返回值： CheckPath类对象
]]
function _CheckPath.new_withoutLevel(self, checkPath)
   
    local statusTab = {};
	for level=1, 5 do
		local result, checkStatus = _getChkStatusByUnitType(level, checkPath);
		-- ngx.log(ngx.ERR, "===> _CheckPath.new level ", level, ", checkStatus: ", checkStatus, ", type: ", type(checkPath), " <===");
		statusTab[level] = checkStatus;
	end
	
	return setmetatable({ 
		_check_path 	= checkPath,
		_dest_level 	= 0,
		_status_table   = statusTab
	}, mt);
end

---------------------------------------------------------------------------
-- function _CheckPath.changeStatus(self, checkStatus)	
	
	-- local currLevel = self._curr_level;
	-- if checkStatus == "12" then 
	
		-- self._status_table[currLevel] = checkStatus;
		
	-- elseif checkStatus == "11" then
	
		-- self._status_table[currLevel] = checkStatus;
		-- if currLevel<5 and self._status_table[currLevel+1] ~= "11" then -- -- 单级审核，下级为0*, 如果为多级审核，下级状态应该为11
			-- for tempLevel=currLevel+1, 5 do
				-- self._status_table[tempLevel] = "11";
			-- end
		-- end
		
	-- end
	-- self.syncCheckPath(self);
	
	-- return self._check_path;
-- end

---------------------------------------------------------------------------
function _CheckPath.setCheckStatus(self, level, checkStatus)
	self._status_table[level] = checkStatus;
	self.syncCheckPath(self);
end


---------------------------------------------------------------------------
function _CheckPath.syncCheckPath(self)
	local newCheckPath = "";
	for level=1, 5 do
		newCheckPath = newCheckPath .. self._status_table[level];
	end
	self._check_path = newCheckPath;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取审核路径
	作者：   申健 2015-03-13
	返回值： 完整的审核路径
]]
function _CheckPath.getCheckPath(self)
	return 	self._check_path;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取最终审核目标
	作者：    申健 2015-04-01
	返回值1： destUnitLevel 最终共享目标
	返回值2： currUnitLevel 当前审核单位
	返回值3： tempStatus    审核状态：10待审核，11审核通过，12未通过，13正在下级审核
]]
function _CheckPath.getDestUnit(self)
	
	local destUnitLevel = 0;
	local currUnitLevel = 0;
	local tempStatus 	= "";
	local isChecking    = false;

	for unitLevel=1, 5 do
			
		local checkStatus = self._status_table[unitLevel];
		-- ngx.log(ngx.ERR, "===> currentLevel:[" .. unitLevel .. "], checkStatus: [" .. checkStatus .. "]");
		local firstChar = string.sub(checkStatus, 1, 1);
		if firstChar == "0" then
		
		elseif firstChar == "1" then
		
			if destUnitLevel == 0 then
				destUnitLevel = unitLevel;
			end
			
			if checkStatus=="10" then
				
				currUnitLevel = unitLevel;
				tempStatus = "10";
				
			elseif checkStatus=="11" then
				if tempStatus ~= "" and tempStatus ~= "11" then
					tempStatus = "13";
					isChecking = true;
				else
					tempStatus = "11";
				end
				if currUnitLevel == 0 then
					currUnitLevel = unitLevel;
				end
			elseif checkStatus=="12" then
				tempStatus = "12";
				currUnitLevel = unitLevel;
				break;
			end
		end
	end

	return destUnitLevel, currUnitLevel, tempStatus;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取审核路径中指定级别单位的审核状态
	作者：   申健 2015-03-13
	参数：   level  			单位级别：1省、2市、3区、4校、5分校
	返回值： 审核状态：00不需要审核，10待审核，11审核通过，12审核不通过
]]
function _CheckPath.getCheckStatusByLevel(self, level)
	return 	self._status_table[level];
end

---------------------------------------------------------------------------
--[[
	局部函数：获取指定级别的单位是否能够修改审核状态
	作者：   申健 2015-03-13
	参数：   unitId  			单位ID
	参数： 	 checkPath  		审核路径
	返回值： CheckPath类对象
]]
function _CheckPath.canModifyStatus(self)
	
	local currStatus = self._status_table[self._curr_level];
	
	if currStatus == "11" or currStatus == "12" then -- 只有审核通过或审核未通过的可以修改
		if self._curr_level == 1 then --共享给省的，都可以修改
			return true;
		else
			local upLevelStatus = self._status_table[self._curr_level-1];
			if upLevelStatus == "00" then -- 单级审核的可以修改审核状态
				return true;
			elseif upLevelStatus == "10" then -- 多级审核，上级单位尚未审核的
				return true;
			else
				return false;
			end
		end
	else
		return false;
	end
	
end

---------------------------------------------------------------------------
--[[
	局部函数：获取指定级别的单位是否可以代替下级审核资源
	作者：   申健 2015-07-25
	返回值： true 可以代替下级审核；false 不可以代审
]]
function _CheckPath.canSupersedeCheck(self)
	-- 当前单位为共享目标
	-- 下级单位的审核状态为待审核；
	local destLevel = self: getDestUnit();
	local nowLevel, nowStatus = self: getNowStatus();
	
	if destLevel ~= nowLevel and self._curr_level < nowLevel and nowStatus == "10" then
		return true;
	end
	return false;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取当前级别的审核状态
	作者：   申健 2015-03-13
	返回值： string
]]
function _CheckPath.getCurrentLevelStatus(self)
	return self._status_table[self._curr_level];
end

---------------------------------------------------------------------------
--[[
	描   述： 获取当前的审核状态（并非当前审核单位的审核状态，而是该记录目前总的审核状态是什么样）
	作   者： 申健 2015-06-03
	返回值1： currUnitLevel 最终共享目标
	返回值2： currentStauts 当前审核单位
]]
function _CheckPath.getNowStatus(self)
	
	local nowLevel  = 0;
	local nowStatus = "";  
    local validFlag = false; -- 有效标识，用来过滤审核路径中低级的不需要审核的单位
	for unitLevel = 5, 1, -1 do			
		local checkStatus = self._status_table[unitLevel];
		-- ngx.log(ngx.ERR, "===> currentLevel:[" .. unitLevel .. "], checkStatus: [" .. checkStatus .. "]");
		
		if checkStatus == "10" or checkStatus == "12" then
            validFlag = true;
			return unitLevel, checkStatus;
		elseif checkStatus == "11" then
            validFlag = true;
			nowLevel  = unitLevel;
			nowStatus = checkStatus;
		elseif checkStatus == "00" and validFlag then 
			break;
		end

	end

	return nowLevel, nowStatus;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取当前总的审核状态
	作者：   申健 2015-03-13
	返回值： string
]]
function _CheckPath.getNowCheckLevelAndState(self)
	local currLevel, currStatus = self: getNowStatus();
	-- ngx.log(ngx.ERR, "[sj_log]->[multi_check]-> currLevel:[", currLevel, "], currStatus: [", currStatus,"]");
	local levelNameTab   = { "本省", "本市", "本区", "本校", "本校" };
	local currLevelName  = levelNameTab[currLevel]; 
	local statusValueTab = { ["10"]="待审核", ["11"]="审核通过", ["12"]="未通过"};
	local statusStr      = statusValueTab[currStatus];
	
	local currStatusStr  = currLevelName .. "-" .. statusStr;
	return currStatusStr;
end

---------------------------------------------------------------------------

return _CheckPath;