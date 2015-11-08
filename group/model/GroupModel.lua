---------------------------------------------------------------------------

local _GroupModel = {};

--[[
	局部函数：查询群组
	作者：刘全锋 2015-08-05
	参数：groupId	--群号
	参数：groupName	--群名
	参数：creator	--创建人
	参数：userNo		--成员编号
	参数：platTp		--业务系统类型 0系统、1云平台、2区域均衡、3教研、4学习模块、5高师实训
	参数：platId		--系统标识
	参数：useRg		--群组使用范围 1教师、2学生、3混搭
	参数：groupTp	--业务群组类型 1机构组，2人员组
	
]]


local function queryGroup(self, groupId, groupName, creator, userNo, platTp, platId, useRg, groupTp,pageNumber, pageSize)
	
	local DBUtil = require "common.DBUtil";
	local db = DBUtil: getDb();
	
	local sql = "select ID,GROUP_NAME,PLAT_TYPE ,PLAT_ID,GROUP_DESC,GROUP_NOTICE,B_USE,CREATE_TIME,GROUP_LEVEL,LEVEL_ORG_ID,B_REQUEST,AVATER_URL from t_base_group_new where 1=1 ";
	
	local whereSql = "";
	
	local queryCount = "select count(1) as count from t_base_group_new where 1=1 ";
	
	--群号
	if groupId ~= nil and groupId ~= "" then	
		whereSql = whereSql .. " and ID="..tonumber(groupId);
	end

	--群名
	if groupName ~= nil and groupName ~= "" then	
	   whereSql = whereSql .. " and GROUP_NAME like '%"..ngx.decode_base64(groupName).."%'";
	end

	--创建人
	if creator ~= nil and creator ~= "" then	
		whereSql = whereSql .. " and ID in (select b.GROUP_ID from t_sys_loginperson a,t_base_group_member_new b where a.PERSON_NAME='"..ngx.quote_sql_str(creator).."' and a.IDENTITY_ID=b.IDENTITY_ID and a.PERSON_ID=PERSON_ID)";
	end

	--成员编号
	if (userNo ~= nil and userNo ~= "") and (args["userId"] ~= nil and args["userId"] ~= "") then
		whereSql = whereSql .. " and ID=(select GROUP_ID from t_base_group_member_new where PERSON_ID="..tonumber(keyWord).." and IDENTITY_ID="..tonumber(keyWord)..")";
	end

	--业务系统类型 0系统、1云平台、2区域均衡、3教研、4学习模块、5高师实训
	if platTp ~= nil and platTp ~= "" then
		whereSql = whereSql .. " and USE_RANGE="..tonumber(platTp);
	end

	--系统标识
	if platId ~= nil and platId ~= "" then
		whereSql = whereSql .. " and GROUP_TYPE="..tonumber(platId);
	end

	--群组使用范围 1教师、2学生、3混搭
	if useRg ~= nil and useRg ~= "" then
		whereSql = whereSql .. " and USE_RANGE="..tonumber(useRg);
	end

	--业务群组类型 1机构组，2人员组
	if groupTp ~= nil and groupTp ~= "" then	
		whereSql = whereSql .. " and GROUP_TYPE="..tonumber(groupTp);
	end
	
	local per_count = db:query(queryCount..whereSql);
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local sql_limit = " limit "..offset..","..limit;
	local totalRow = per_count[1]["count"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	
	whereSql = whereSql..sql_limit;
	
	local res, err, errno, sqlstate = db:query(sql..whereSql);
	
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local resultListObj = {};
	for i=1, #res do
		local record = {};
				
		record.ID 	  		= res[i]["ID"];
		record.GROUP_NAME   	= res[i]["GROUP_NAME"];
		record.PLAT_TYPE   	= res[i]["PLAT_TYPE"];
		record.PLAT_ID 		= res[i]["PLAT_ID"];
		record.GROUP_DESC   	= res[i]["GROUP_DESC"];
		record.GROUP_NOTICE 	= res[i]["GROUP_NOTICE"];
		record.B_USE 		= res[i]["B_USE"];
		record.CREATE_TIME 	= res[i]["CREATE_TIME"];
		record.GROUP_LEVEL 		= res[i]["GROUP_LEVEL"];
		record.LEVEL_ORG_ID 		= res[i]["LEVEL_ORG_ID"];
		record.B_REQUEST 		= res[i]["B_REQUEST"];
		record.AVATER_URL 		= res[i]["AVATER_URL"];
		
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success  = true;
	resultJsonObj.records  = totalRow;
	resultJsonObj.total 	= totalPage;
	resultJsonObj.page 		= pageNumber;
	resultJsonObj.rows 		= resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	return resultJsonObj;
end

_GroupModel.queryGroup = queryGroup;