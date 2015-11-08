--[[
#申健 2015-03-24
#描述：资源定制的基础函数
]]

local _ResourceCustomize = {};

local todayMaxCount =10;
-- 可定制的资源类型
local cusType = {
	{ code = 1, value = "flash动画"},
	{ code = 2, value = "3d动画"},
	{ code = 3, value = "工具软件"},
	{ code = 4, value = "视频录制"},
	{ code = 5, value = "视频处理"},
	{ code = 6, value = "视频录制及处理"}
};
local reasonType = {
     {code = 1,value = "Ppt可实现"},
     {code = 2,value = "超过今天的名额"},
     {code = 3,value = "期望时间无法完成"},
	 {code = 4,value = "不属于业务范畴"},
	 {code = 5,value = "以上联系方式均联系不到"},
	 {code = 6,value = "其它"},
}
--local todayMaxCount = 5;

---------------------------------------------------------------------------
--[[
	局部函数：	获取今天已经提交的定制信息的数量
	作者： 		申健 2015-03-09
	参数： 		unitType  		单位类型：1省、2市、3区、4总校、5分校
	参数： 		checkPath  		审核路径
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]
local function getResType(self)
   return cusType
end
_ResourceCustomize.getResType = getResType;

local function reason(self)
   return reasonType
end
_ResourceCustomize.reason = reason;

--[[
	局部函数：	获取今天已经提交的定制信息类型
	作者： 		申健 2015-04-12
	参数： 		res_type  		参数值
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]
local function getResTypeValue(self,res_type)

for key, value in pairsByKeys(cusType) do  
    if res_type == key then  
        return key  
    end  
end 
end 

_ResourceCustomize.getResTypeValue = getResTypeValue;


---------------------------------------------------------------------------
--[[
	局部函数：	获取今天已经提交的定制信息的数量
	作者： 		申健 2015-03-09
	参数： 		unitType  		单位类型：1省、2市、3区、4总校、5分校
	参数： 		checkPath  		审核路径
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]

local function getTodayCustomizeCount(self)
	local currentDate   = os.date("%Y-%m-%d");
    local todayStart    = currentDate .. " 00:00:00";
    local todayEnd      = currentDate .. " 23:59:59";
    --连接mysql
    local DBUtil = require "multi_check.model.DBUtil";
	local db     = DBUtil: getDb();
    local sql = "SELECT COUNT(1) AS TODAY_COUNT FROM T_BASE_RES_CUSTOMIZE WHERE CREATE_TIME BETWEEN '" .. todayStart .. "' AND '"..todayEnd.."'";
    local res, err, errno, sqlstate = db:query(sql);

	if not res then
		ngx.log(ngx.ERR, "===> 查询定制信息列表出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
		return {success=false, info="查询数据出错。"};
	end
    local todayCount = tonumber(res[1]["TODAY_COUNT"]);
		-- ngx.log(ngx.ERR,"----------todayCount---------"..todayCount);
    -- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
    
	return todayCount;
end

_ResourceCustomize.getTodayCustomizeCount = getTodayCustomizeCount;

-------------------------------------------------------------------------------------
--[[
	局部函数：	保存用户的输入历史信息
	作者： 		申健 2015-03-21
	参数： 		paramObj  		参数对象
]]

local function savePersonHistory(self, paramObj)
	local ssdblib = require "resty.ssdb"
	local ssdb = ssdblib:new()
	
	local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
	if not ok then
		say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end
	
	local results, err = ssdb:multi_hset(
		"resCusHistory_" .. paramObj.person_id .. "_" .. paramObj.identity_id, 
		"telephone", paramObj.telephone, 
		"email", paramObj.email, 
		"qq", paramObj.qq
	);
	if not results then  
		ngx.log(ngx.ERR, "保存用户的输入历史失败！")
	end
	
	ssdb:set_keepalive(0, v_pool_size)
end

_ResourceCustomize.savePersonHistory = savePersonHistory;

-------------------------------------------------------------------------------------
--[[
	局部函数：	保存用户的定制信息
	作者： 		申健 2015-03-21
	参数： 		paramObj  		参数对象
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作结果信息
]]

local function saveCustomizeInfo(self, paramObj)
    --ngx.log(ngx.ERR,"-------------------"..paramObj.auto);
	if paramObj.auto  == "0" then
	   -- ngx.log(ngx.ERR,"----------0---------");
		local myTs 		  = require "resty.TS"
		local currentTS   = myTs.getTs();
		local currentTime = os.date("%Y-%m-%d %H:%M:%S");
	
		local DBUtil = require "multi_check.model.DBUtil";
		local db     = DBUtil: getDb();
	
		local todayCount = self: getTodayCustomizeCount();
		
        --ngx.log(ngx.ERR,"----------todayCount---------"..todayCount);
	    --ngx.log(ngx.ERR,"----------todayMaxCount---------"..todayMaxCount);
		if todayCount < todayMaxCount then 
		--ngx.log(ngx.ERR,"----------insert---------");
        
			local sql = "INSERT INTO dsideal_db.t_base_res_customize(STAGE_ID, SUBJECT_ID, PERSON_ID, IDENTITY_ID, PERSON_NAME, BUREAU_ID, BUREAU_NAME, CREATE_TIME, STATUS ,STAGE_NAME, SUBJECT_NAME, UPDATE_TS, EMAIL, TELEPHONE, QQ, RES_NAME, RES_TYPE, RES_COMMENT, EXPECT_TIME,RES_MSG ) VALUES ( " .. paramObj.stage_id .. "," .. paramObj.subject_id .. "," .. paramObj.person_id .."," .. paramObj.identity_id .."," .. ngx.quote_sql_str(paramObj.person_name) .. "," .. paramObj.bureau_id ..",'" .. paramObj.bureau_name .."','" .. currentTime .."', 1,'" .. paramObj.stage_name .."','" .. paramObj.subject_name .."'," .. currentTS .."," .. ngx.quote_sql_str(paramObj.email) .."," .. ngx.quote_sql_str(paramObj.telephone) .."," .. ngx.quote_sql_str(paramObj.qq) .."," .. ngx.quote_sql_str(paramObj.res_name) .."," .. paramObj.res_type .."," ..  ngx.quote_sql_str(paramObj.res_comment) ..",'" .. paramObj.expect_time .. "','"..paramObj.res_msg.."');";
        
			ngx.log(ngx.ERR, "===> 保存资源定制信息的SQL语句：[", sql, "]");
        
			local result, err, errno, sqlstate = db: query(sql);
        
        -- 将数据库连接返回连接池
			DBUtil: keepDbAlive(db);
        
			if not result then
			ngx.log(ngx.ERR,"----------not---------");
				ngx.log(ngx.ERR, "===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
				return false, "保存信息失败";
			end
        
			_ResourceCustomize:savePersonHistory(paramObj);
        --ngx.log(ngx.ERR,"----------yes---------");
			return true, "保存信息成功";
        
		else
		--ngx.log(ngx.ERR,"----------esle yes---------");
			return false, "已经超过当日的定制数量，请明日再进行申请。";
		end

	else  
	--ngx.log(ngx.ERR,"----------no---------");
	    return false, "未通过，已超过今天的名额1";
	end
	
	
end

_ResourceCustomize.saveCustomizeInfo = saveCustomizeInfo;




---------------------------------------------------------------------------
local function _getConditionSql(conditionJson)

	local sql = "";
	if conditionJson.stage_id ~= nil and conditionJson.stage_id ~= "" then
		sql = sql .. " AND STAGE_ID=" .. conditionJson.stage_id;
	end
	
	if conditionJson.subject_id ~= nil and conditionJson.subject_id ~= "" then
		sql = sql .. " AND SUBJECT_ID=" .. conditionJson.subject_id;
	end
	
	if conditionJson.check_status ~= nil and conditionJson.check_status ~= "" then
		sql = sql .. " AND STATUS=" .. conditionJson.check_status;
	end
	ngx.log(ngx.ERR, "===> 查询定制信息的条件语句：[", sql, "] <===");
	
	return sql;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取定制信息列表
	作者： 		申健 2015-03-23
	参数： 		unitType  		单位类型：1省、2市、3区、4总校、5分校
	参数： 		checkPath  		审核路径
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]

local function getCustomizeList(self, pageNumber, pageSize, paramObj)

	ngx.log(ngx.ERR,"----------pageNumber---------"..pageNumber);
	local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	
	local conditionSql = _getConditionSql(paramObj)
	
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_RES_CUSTOMIZE WHERE 1=1 " .. conditionSql .. ";";
	
	local res, err, errno, sqlstate = db:query(countSql);
	if not res then
		ngx.log(ngx.ERR, "===> 查询定制信息列表出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
		return {success=false, info="查询数据出错。"};
	end
	

	local totalRow = res[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	--ngx.log(ngx.ERR,"----------totalPage---------"..totalPage);
	local offset = pageSize*pageNumber-pageSize;
	--ngx.log(ngx.ERR,"----------offset---------"..offset);
	local limit  = pageSize;
	
	--ngx.log(ngx.ERR,"----------limit---------"..limit);
	-- DATE_FORMAT(CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME
	
	local sql = "SELECT ID, STAGE_ID, SUBJECT_ID, PERSON_ID, IDENTITY_ID, PERSON_NAME, BUREAU_ID, BUREAU_NAME, DATE_FORMAT(CREATE_TIME,'%Y-%m-%d') AS CREATE_TIME, STATUS, STAGE_NAME, SUBJECT_NAME, UPDATE_TS, EMAIL, TELEPHONE, QQ, RES_NAME, RES_TYPE, RES_COMMENT, DATE_FORMAT(EXPECT_TIME,'%Y-%m-%d') AS EXPECT_TIME, CHECK_MSG, RES_MSG, DATE_FORMAT(CHECK_TIME,'%Y-%m-%d') AS CHECK_TIME FROM T_BASE_RES_CUSTOMIZE WHERE 1=1 " .. conditionSql .. " ORDER BY ID DESC LIMIT " .. offset .. "," .. limit .. ";";
	
	ngx.log(ngx.ERR, "===> 查询审核列表 sql ===> ", sql);
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		ngx.log(ngx.ERR, "===> 查询定制信息列表出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
		return {success=false, info="查询数据出错。"};
	end
	local resArray = {};
	for i=1, #res do
	
		local record = {};
		record.id 			     	 = res[i]["ID"];
		record.stage_id 		     = res[i]["STAGE_ID"];
		record.stage_name 		     = res[i]["STAGE_NAME"];
		record.subject_id 		     = res[i]["SUBJECT_ID"];
		record.subject_name 		 = res[i]["SUBJECT_NAME"];
		record.person_id 		     = res[i]["PERSON_ID"];
		record.identity_id 	     	 = res[i]["IDENTITY_ID"];
		record.person_name 	     	 = res[i]["PERSON_NAME"];
		record.bureau_name		     = res[i]["BUREAU_NAME"];
		record.create_time		     = res[i]["CREATE_TIME"];
		record.status  	     		 = res[i]["STATUS"];
		record.update_ts 			 = res[i]["UPDATE_TS"];
		record.email  	     		 = res[i]["EMAIL"];
		record.telephone		     = res[i]["TELEPHONE"];
		record.qq		     		 = res[i]["QQ"];
		record.res_name 	  	 	 = res[i]["RES_NAME"];
		record.res_type    			 = res[i]["RES_TYPE"];
		record.res_comment 	     	 = res[i]["RES_COMMENT"];
		record.expect_time	 	  	 = res[i]["EXPECT_TIME"];
		record.check_msg	 	  	 = res[i]["CHECK_MSG"];
		record.res_msg	 	  	 = res[i]["RES_MSG"];
		record.check_time	 	  	 = res[i]["CHECK_TIME"];
		table.insert(resArray, record);
	end

	local resListJson = {};
	resListJson.success    = true;
	resListJson.totalRow   = totalRow;
	resListJson.totalPage  = totalPage;
	resListJson.pageNumber = pageNumber;
	resListJson.pageSize   = pageSize;
	resListJson.list = resArray;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return resListJson;
end

_ResourceCustomize.getCustomizeList = getCustomizeList;

---------------------------------------------------------------------------
--[[
	局部函数：	审核定制信息
	作者： 		陈丽月 2015-04-13
	参数： 		pageNumber  	审核状态
	参数： 		pageSize  		审核信息
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]
local function getMyCustomizeList(self, pageNumber, pageSize, personId, identityId)
    
    local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_RES_CUSTOMIZE WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId;
	local res, err, errno, sqlstate = db:query(countSql);
	if not res then
		ngx.log(ngx.ERR, "===> 查询定制信息列表出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
		return {success=false, info="查询数据出错。"};
	end
	local totalRow = res[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset = pageSize*pageNumber-pageSize;
	local limit  = pageSize;
	ngx.log(ngx.ERR, "===> 获取教师的权限 ===> 人员ID：[", personId, "], 身份ID：[", identityId, "]");
	
	local sql = "SELECT ID, PERSON_ID, IDENTITY_ID, PERSON_NAME, DATE_FORMAT(CREATE_TIME,'%Y-%m-%d') AS CREATE_TIME, STATUS, RES_NAME, RES_TYPE, RES_COMMENT, DATE_FORMAT(EXPECT_TIME,'%Y-%m-%d') AS EXPECT_TIME, CHECK_MSG, RES_MSG, DATE_FORMAT(CHECK_TIME,'%Y-%m-%d') AS CHECK_TIME FROM T_BASE_RES_CUSTOMIZE WHERE PERSON_ID=" .. personId .. " AND IDENTITY_ID=" .. identityId .." ORDER BY ID DESC LIMIT " .. offset .. "," .. limit .. ";";
	
	ngx.log(ngx.ERR, "===> 获取教师的权限 ===> SQL语句：[", sql, "]");
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	local resArray = {};
	for i=1, #res do
	
		local record = {};
		record.id 			     	 = res[i]["ID"];
		record.person_id 		     = res[i]["PERSON_ID"];
		record.identity_id 	     	 = res[i]["IDENTITY_ID"];
		record.person_name 	     	 = res[i]["PERSON_NAME"];
		record.create_time		     = res[i]["CREATE_TIME"];
		record.status  	     		 = res[i]["STATUS"];
		record.res_name 	  	 	 = res[i]["RES_NAME"];
		record.res_type    			 = res[i]["RES_TYPE"];
		record.res_comment 	     	 = res[i]["RES_COMMENT"];
		record.expect_time	 	  	 = res[i]["EXPECT_TIME"];
		record.check_msg	 	  	 = res[i]["CHECK_MSG"];
		record.res_msg	 	  	 = res[i]["RES_MSG"];
		record.check_time	 	  	 = res[i]["CHECK_TIME"];
		table.insert(resArray, record);
	end

	local resListJson = {};
	resListJson.success    = true;
	resListJson.totalRow   = totalRow;
	resListJson.totalPage  = totalPage;
	resListJson.pageNumber = pageNumber;
	resListJson.pageSize   = pageSize;
	resListJson.list = resArray;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return resListJson;
end
_ResourceCustomize.getMyCustomizeList = getMyCustomizeList;
---------------------------------------------------------------------------
--[[
	局部函数：	审核定制信息
	作者： 		申健 2015-03-23
	参数： 		checkStatus  	审核状态
	参数： 		checkMsg  		审核信息
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]

local function check(self, id, checkStatus, checkMsg)
    local myTs 		  = require "resty.TS"
	local currentTS   = myTs.getTs();
    local currentTime = os.date("%Y-%m-%d %H:%M:%S");
    local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
    local sql = "UPDATE T_BASE_RES_CUSTOMIZE SET STATUS=" .. checkStatus .. ",CHECK_TIME='" .. currentTime .. "', CHECK_MSG=" .. ngx.quote_sql_str(checkMsg) .." WHERE ID=" .. id;
    local res, err, errno, sqlstate = db:query(sql);
	if not res then
		ngx.log(ngx.ERR, "===> 查询定制信息列表出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
		return {success=false, info="查询数据出错。"};
	end
    -- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return true;
end

_ResourceCustomize.check = check;

---------------------------------------------------------------------------
--[[
	局部函数：	获取定制信息根据id
	作者： 		陈丽月 2015-04-10
	参数： 		id  		定制信息的ID  
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]

local function getCustomizeById(self,id)
     
	 local currentTime = os.date("%Y-%m-%d %H:%M:%S");
     local DBUtil = require "multi_check.model.DBUtil";
	 local db = DBUtil: getDb();
     local sql ="SELECT ID, PERSON_NAME, DATE_FORMAT(CREATE_TIME,'%Y-%m-%d') AS CREATE_TIME, STAGE_NAME, SUBJECT_NAME,EMAIL, TELEPHONE, QQ, RES_NAME, RES_TYPE, RES_COMMENT, BUREAU_NAME, DATE_FORMAT(EXPECT_TIME,'%Y-%m-%d') AS EXPECT_TIME FROM T_BASE_RES_CUSTOMIZE WHERE  id="..id;
     local res, err, errno, sqlstate = db:query(sql);
	 if not res then 
	    ngx.log(ngx.ERR, "===> 查询定制信息出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
        return {success=false, info="查询数据出错。"};
	end
	local getCustomizeInfo =res
	local results ={};
	results.success = true;
	results.list = getCustomizeInfo;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return results;
    
end
_ResourceCustomize.getCustomizeById=getCustomizeById;
 ---------------------------------------------------------------------------
--[[
	局部函数：	修改定制信息
	作者： 		陈丽月    2015-04-13
	参数： 		id  		定制信息的ID
	参数： 		resType     定制资源的类别  		
	参数： 		resComment  定制资源的描述
	返回值1：	boolean 操作是否成功 true成功，false失败
	返回值2：	操作成功时返回单位的审核状态，操作失败时返回错误信息
]]

local function modifyCustomizeInfo(self, id, resType, resComment, res_msg)
ngx.log(ngx.ERR, "ERR MSG =====> 参数resComment不能为空！"..res_msg);
	
    local currentTime = os.date("%Y-%m-%d %H:%M:%S");
    local DBUtil = require "multi_check.model.DBUtil";
	local db = DBUtil: getDb();
    local sql = "UPDATE T_BASE_RES_CUSTOMIZE SET RES_Type=" .. ngx.quote_sql_str(resType) .. ",RES_MSG=" .. ngx.quote_sql_str(res_msg) .. ", RES_COMMENT=" .. ngx.quote_sql_str(resComment) .. " WHERE ID=" .. id;
    local res, err, errno, sqlstate = db:query(sql);
	if not res then
		ngx.log(ngx.ERR, "===> 修改定制信息出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
		return {success=false, info="查询数据出错。"};
	end
    -- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return true;
    
end

_ResourceCustomize.modifyCustomizeInfo = modifyCustomizeInfo;


return _ResourceCustomize;