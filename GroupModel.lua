---------------------------------------------------------------------------
-- 描述：群组功能 -> 查询群组、添加群组、修改群组
---------------------------------------------------------------------------

local SSDBUtil = require "common.SSDBUtil";
local DBUtil   = require "common.DBUtil";
local tsModel  = require "resty.TS";


local _GroupModel = {};
local quote = ngx.quote_sql_str



-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 获取T_BASE_GroupModel_NEW表的新的ID（从SSDB中获取）
-- 日    期： 2015年8月6日
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function getNewRecordPk()
    return SSDBUtil: incr("t_base_group_new_pk");
end

_GroupModel.getNewRecordPk = getNewRecordPk;



-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 获取T_BASE_GroupModel_MEMBER_NEW表的新的ID（从SSDB中获取）
-- 日    期： 2015年8月6日
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function getNewRecordMemberPk()
    return SSDBUtil: incr("t_base_group_member_new_pk");
end

_GroupModel.getNewRecordMemberPk = getNewRecordMemberPk;

--[[
	局部函数：查询群组
	作者：刘全锋 2015-08-05
	参数：groupId	--群号
	参数：groupName	--群名
	参数：creator	--创建人
	参数：personId		--成员编号
	参数：identityId		--成员权限
	参数：platTp		--业务系统类型 0系统、1云平台、2区域均衡、3教研、4学习模块、5高师实训
	参数：platId		--系统标识
	参数：useRg		--群组使用范围 1教师、2学生、3混搭
	参数：groupTp	--业务群组类型 1机构组，2人员组
	
]]


local function queryGroup(keyWord , personId, identityId, pageNumber, pageSize)
	
	local db = DBUtil: getDb();
	
	local sql = "select g.ID,g.GROUP_NAME,GROUP_TYPE,g.PLAT_TYPE ,g.PLAT_ID,g.GROUP_DESC,g.GROUP_NOTICE,g.B_USE,g.CREATE_TIME,g.GROUP_LEVEL,g.LEVEL_ORG_ID,g.B_REQUEST,g.AVATER_URL from t_base_Group_new g left join t_base_group_member_new m on m.B_USE=1 and m.GROUP_ID=g.ID and m.PERSON_ID="..personId.." and m.IDENTITY_ID="..identityId.." where g.B_USE=1 ";
	
	
	
	
	local whereSql = "";
	
	local queryCount = "select count(1) as count from t_base_Group_new g left join t_base_group_member_new m on m.B_USE=1 and m.GROUP_ID=g.ID and m.PERSON_ID="..personId.." and m.IDENTITY_ID="..identityId.." where g.B_USE=1 ";
	
	
	--群组名或创建人查询
	whereSql = whereSql .. "and (GROUP_NAME like "..quote("%"..keyWord.."%");
	whereSql = whereSql .. " or g.ID in (select b.GROUP_ID from t_sys_loginperson a,t_base_Group_member_new b where a.PERSON_NAME like "..quote("%"..keyWord.."%").." and a.IDENTITY_ID=b.IDENTITY_ID and a.PERSON_ID=b.PERSON_ID and b.MEMBER_TYPE=0)";
	
	if tonumber(keyWord)  ~= nil then
		whereSql = whereSql .." or ID="..keyWord;
	end
	
	whereSql = whereSql ..")";	

	--成员编号，成员权限联合查询群组
	if (personId ~= nil and personId ~= "") and (identityId ~= nil and identityId ~= "") then
			
		local CacheUtil = require "common.CacheUtil";
		local cache = CacheUtil: getRedisConn();
		local schShengID = cache:hget("person_"..personId.."_"..identityId,"sheng");
		local schShiID = cache:hget("person_"..personId.."_"..identityId,"shi");
		local schQuID = cache:hget("person_"..personId.."_"..identityId,"qu");
		local schXiaoID = cache:hget("person_"..personId.."_"..identityId,"xiao");
		
		if schShengID==ngx.null then
			schShengID = 0;
		end
		
		if schShiID==ngx.null then
			schShiID = 0;
		end
		
		if schQuID==ngx.null then
			schQuID = 0;
		end
		
		if schXiaoID==ngx.null then
			schXiaoID = 0;
		end
		
		if (identityId == "5") then
			whereSql = whereSql .. " and (LEVEL_ORG_ID="..tonumber(schShengID).. " or LEVEL_ORG_ID="..tonumber(schShiID).." or LEVEL_ORG_ID="..tonumber(schQuID).." or LEVEL_ORG_ID="..tonumber(schXiaoID)..")";	
		end
	end
		
	ngx.log(ngx.ERR,"sql======="..queryCount..whereSql);
		
	local per_count = db:query(queryCount..whereSql);
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local sql_limit = " order by id desc limit "..offset..","..limit;
	local totalRow = per_count[1]["count"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	
	
	whereSql = whereSql..sql_limit;
	
	ngx.log(ngx.ERR,"=======333====="..sql..whereSql);
	
	local res, err, errno, sqlstate = db:query(sql..whereSql);
	
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local resultListObj = {};
	
	ngx.log(ngx.ERR,"====1111111=======");
	
	for i=1, #res do
		local record = {};
		
		
		local user_state = 2;
				
		record.ID 	  			= res[i]["ID"];
		record.GROUP_NAME   	= res[i]["GROUP_NAME"];
		record.GROUP_TYPE   	= res[i]["GROUP_TYPE"];
		record.PLAT_TYPE   		= res[i]["PLAT_TYPE"];
		record.PLAT_ID 			= res[i]["PLAT_ID"];
		record.GROUP_DESC   	= res[i]["GROUP_DESC"];
		record.GROUP_NOTICE 	= res[i]["GROUP_NOTICE"];
		record.CREATE_TIME	 	= res[i]["CREATE_TIME"];
		record.GROUP_LEVEL 		= res[i]["GROUP_LEVEL"];
		record.LEVEL_ORG_ID		= res[i]["LEVEL_ORG_ID"];
		record.B_REQUEST 		= res[i]["B_REQUEST"];
		record.AVATER_URL 		= res[i]["AVATER_URL"];
		record.STATE_ID 		= user_state;
		
		
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj		= {};
	resultJsonObj.success  = true;	
	resultJsonObj.totalRow   = tonumber(totalRow);
	resultJsonObj.totalPage  = totalPage;
	resultJsonObj.pageNumber = tonumber(pageNumber);
	resultJsonObj.pageSize 	 = tonumber(pageSize);
	resultJsonObj.rows 		= resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	
	ngx.log(ngx.ERR,"============");
	
	return true,resultJsonObj;
end

_GroupModel.queryGroup = queryGroup;

---------------------------------------------------------------------------

--[[
	局部函数：	查询我所在群组
	作者：		刘全锋 2015-08-07
	参数：		personId		--成员编号
	参数：		identityId	--成员权限
]]


local function queryMyGroup(personId, identityId,pageNumber, pageSize)
	
	local db = DBUtil: getDb();
	
	local sql = "select g.ID,g.GROUP_NAME,g.GROUP_TYPE,g.PLAT_TYPE ,g.PLAT_ID,g.GROUP_DESC,g.GROUP_NOTICE,g.B_USE,g.CREATE_TIME,g.GROUP_LEVEL,g.LEVEL_ORG_ID,g.B_REQUEST,g.AVATER_URL, m.ID AS MEMBER_ID, m.MEMBER_TYPE,m.STATE_ID from t_base_Group_new g right JOIN t_base_group_member_new m on ";
	
	
	
	local queryCount = "select count(1) as count from t_base_Group_new g right join t_base_group_member_new m on ";
	
	local whereSql = "m.GROUP_ID = g.ID where m.B_USE=1 and g.B_USE=1 and m.PERSON_ID = " ..personId.. " and m.IDENTITY_ID="..identityId;
	
	local per_count = db:query(queryCount..whereSql);
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local sql_limit = " order by id desc limit "..offset..","..limit;
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
		local countMem = 0;
		
		local countMemSql = "select count(1) as count from t_base_group_member_new where GROUP_ID="..res[i]["ID"].." and STATE_ID=0 and B_USE=1";
		local per_countMem = db:query(countMemSql);
		countMem = tonumber(per_countMem[1]["count"]);
				
		record.ID 	  			= res[i]["ID"];
		record.GROUP_NAME   	= res[i]["GROUP_NAME"];
		record.GROUP_TYPE   	= res[i]["GROUP_TYPE"];
		record.PLAT_TYPE   		= res[i]["PLAT_TYPE"];
		record.PLAT_ID 			= res[i]["PLAT_ID"];
		record.GROUP_DESC   	= res[i]["GROUP_DESC"];
		record.GROUP_NOTICE 	= res[i]["GROUP_NOTICE"];
		record.B_USE 			= res[i]["B_USE"];
		record.CREATE_TIME	 	= res[i]["CREATE_TIME"];
		record.GROUP_LEVEL 		= res[i]["GROUP_LEVEL"];
		record.LEVEL_ORG_ID		= res[i]["LEVEL_ORG_ID"];
		record.B_REQUEST 		= res[i]["B_REQUEST"];
		record.AVATER_URL 		= res[i]["AVATER_URL"];
		record.MEMBER_ID 		= res[i]["MEMBER_ID"];
		record.MEMBER_TYPE 		= res[i]["MEMBER_TYPE"];
		record.STATE_ID 		= res[i]["STATE_ID"];
		record.CHECK_NUM 		= countMem;
		
		table.insert(resultListObj, record);
		
	end
		
	local resultJsonObj		 = {};
	resultJsonObj.success    = true;
	resultJsonObj.totalRow   = tonumber(totalRow);
	resultJsonObj.totalPage  = totalPage;
	resultJsonObj.pageNumber = tonumber(pageNumber);
	resultJsonObj.pageSize 	 = tonumber(pageSize);
	resultJsonObj.rows 		 = resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return true,resultJsonObj;
end

_GroupModel.queryMyGroup = queryMyGroup;

---------------------------------------------------------------------------

--[[
	局部函数：	创建群组
	作者：		刘全锋 2015-08-05
	参数：		paramTable -- 存储参数的table对象
	返回值：	 boolean true操作成功，false操作失败
]]

local function saveGroup(paramTable)


	local newId			= _GroupModel.getNewRecordPk();
	local parentType	= paramTable["parent_type"];
	local parentId		= tonumber(paramTable["parent_id"]);
	local groupName		= quote(paramTable["group_name"]);
	local groupType		= paramTable["group_type"];
	local creatorId		= paramTable["creator_id"];
	local masterId		= paramTable["master_id"];
	local useRange		= paramTable["use_range"];
	local platType		= paramTable["plat_type"];
	local platId		= paramTable["plat_id"];
	local groupDesc		= quote(paramTable["group_desc"]);
	local createTime	= quote(paramTable["create_time"]);
	local avaterUrl		= quote(paramTable["avater_url"]);
	local currentTS		= tsModel.getTs();
	local identityId	= tonumber(paramTable["identityId"]);
	
	
	--查询机构级别、机构级别ID开始
	local db = DBUtil: getDb();
	local sql = "select unit_id,unit_type from t_base_maneger where person_id = "..creatorId.." and identity_id="..identityId.." and b_use = 1  order by unit_id asc limit 1";
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local groupLevel	= "";
	local levelOrgId	= "";
	
	
	
	
	if #res>0 then
			groupLevel	= res[1]["unit_type"];
			levelOrgId	= res[1]["unit_id"];
	else
			local CacheUtil = require "common.CacheUtil";
			local cache = CacheUtil: getRedisConn();
			groupLevel	= 4;
			levelOrgId	= cache:hget("person_"..creatorId.."_"..identityId,"xiao");
	end
	--查询机构级别、机构级别ID结束

	local insertGroupSql = "INSERT INTO T_BASE_GROUP_NEW (ID,PARENT_TYPE,PARENT_ID,GROUP_NAME,GROUP_TYPE,CREATOR_ID,MASTER_ID,USE_RANGE,PLAT_TYPE,PLAT_ID,GROUP_DESC,CREATE_TIME,GROUP_LEVEL,LEVEL_ORG_ID,AVATER_URL,TS) VALUES (" .. newId .. ", " .. parentType .. ", " .. parentId .. ", " .. groupName .. ", " .. groupType .. ", " .. creatorId .. ", " .. masterId .. ", " .. useRange .. ", " .. platType .. ", " .. platId .. ", " .. groupDesc .. ", " ..  createTime  .. ", " .. groupLevel .. ", " .. levelOrgId ..", " .. avaterUrl	..", " .. currentTS .. ") ";
	
	
	local result = DBUtil: querySingleSql(insertGroupSql);
	
	if not result then
		return false, "执行sql语句报错， sql语句：[", insertGroupSql, "]";
	end
	
	
	
	local newMemberId	= _GroupModel.getNewRecordMemberPk();
	local groupId		= newId;
	local personId		= creatorId;
	local checkMsg		= "";
	local stateId		= 1;
	local bUse			= 1;
	local applyTime		= os.date("%Y-%m-%d %H:%M:%S");
	local memberType	= 0;
	local currentTS		= tsModel.getTs();
	
	
	--查询所在学校或教育局的ID开始
	local sql = "select BUREAU_ID from t_base_person where person_id = "..creatorId.." and identity_id="..identityId.." limit 1";
	
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local bureauId	= "";
	
	bureauId	= res[1]["BUREAU_ID"];
	
	
	--查询所在学校或教育局的ID结束

	 local insertMemberSql = "INSERT INTO T_BASE_GROUP_MEMBER_NEW (ID, GROUP_ID, PERSON_ID, IDENTITY_ID, CHECK_CONTENT, STATE_ID, B_USE, APPLY_TIME, MEMBER_TYPE, BUREAU_ID, TS) VALUES (" .. newMemberId .. ", " .. groupId .. ", " .. personId .. ", " .. identityId .. ", " .. ngx.quote_sql_str(checkMsg) .. ", " .. stateId .. ", " .. bUse .. ", " .. ngx.quote_sql_str(applyTime) .. ", " .. memberType .. ", " .. bureauId .. ", " .. currentTS .. ") ;";
	

    local resultMber = DBUtil: querySingleSql(insertMemberSql);
	
    if not resultMber then
        return false;
    else
        return true;
    end
end

_GroupModel.saveGroup = saveGroup;

---------------------------------------------------------------------------

--[[
	局部函数：	修改群组
	作者：		刘全锋 2015-08-05
	参数：		paramTable -- 存储参数的table对象
	返回值：	 boolean true操作成功，false操作失败
]]

local function updateGruop(paramTable)

	local groupId = paramTable["id"];
	if groupId == nil or groupId == ngx.null then
		return false, "id不能为空";
	end

	local fieldTable = {};

	local whereSql = "";
	
		
	local groupName		= paramTable["group_name"];
	if groupName ~= nil and groupName ~= ngx.null then
		fieldTable["GROUP_NAME"] = groupName;
	end
	

	local groupDesc		= paramTable["group_desc"];
	if groupDesc ~= nil and groupDesc ~= ngx.null then
		fieldTable["GROUP_DESC"] = groupDesc;
	end
	
	
	local avaterUrl		= paramTable["avater_url"];
	if avaterUrl ~= nil and avaterUrl ~= ngx.null then
		fieldTable["AVATER_URL"] = avaterUrl;
	end
	

	local updateSql = "UPDATE T_BASE_Group_NEW SET ";
	if next(fieldTable) ~= nil then
		for field, value in pairs(fieldTable) do
			updateSql = updateSql .. " " .. field .. " = " .. quote(value) .. ",";
		end
	else
		return false, "没有获取到需要更新的字段";
	end
	updateSql = string.sub(updateSql, 1, string.len(updateSql)-1);
	
	updateSql = updateSql .. " WHERE ID = " .. groupId .. ";";
	
	local result = DBUtil: querySingleSql(updateSql);
	if not result then
		return false;
	else
		return true;
	end
end

_GroupModel.updateGruop = updateGruop;

---------------------------------------------------------------------------

--[[
	局部函数：	验证云平台最多创建10个群组
	作者：		刘全锋 2015-08-05
	参数：		creatorId 	-- 创建人
	参数：		platTp 		-- 平台ID
	返回值： 	boolean 	true操作成功，false操作失败
]]

local function chkGruopNum(creatorId, platTp)


	local db = DBUtil: getDb();

	local queryCount = "select count(1) as count from T_BASE_Group_NEW where CREATOR_ID = "..tonumber(creatorId).." and PLAT_TYPE = "..tonumber(platTp);
	
	local per_count = db:query(queryCount);
	
	local totalRow = tonumber(per_count[1]["count"]);
	
	if totalRow >= 10 then
		return false;
	else
		return true;
	end
end

_GroupModel.chkGruopNum = chkGruopNum;
---------------------------------------------------------------------------

--[[
	局部函数：	群组名称是否重复
	作者：		刘全锋 2015-08-05
	参数：		creatorId -- 创建人
	参数：		groupName -- 群组名
	返回值： 	boolean true操作成功，false操作失败
]]

local function chkGruopName(creatorId, groupName)

	local db = DBUtil: getDb();
	
	local queryCount = "select count(1) as count from T_BASE_Group_NEW a,T_BASE_ORGANIZATION b where a.CREATOR_ID = "..tonumber(creatorId).." and a.GROUP_NAME = "..quote(groupName) .." or b.ORG_NAME = "..quote(groupName);
		
	local per_count = db:query(queryCount);
	
	local totalRow = tonumber(per_count[1]["count"]);
	
	if totalRow > 1 then
		return false;
	else
		return true;
	end
end


_GroupModel.chkGruopName = chkGruopName;


---------------------------------------------------------------------------

--[[
	局部函数：	根据ID查询群组
	作者：		刘全锋 2015-08-07
	参数：		groupId -- 群组ID
	返回值： 	根据ID查询的数据，空返回false
]]

local function queryGroupById(groupId)

	local db = DBUtil: getDb();
	local sql = "select GROUP_NAME,GROUP_DESC,AVATER_URL from T_BASE_Group_NEW where ID = "..tonumber(groupId).." limit 1";
	
	local queryResult = db:query(sql);
	
	if not queryResult or #queryResult == 0 then
        return false;
    end
	
	local record = {};
    record.GROUP_NAME  = queryResult[1]["GROUP_NAME"];
    record.GROUP_DESC  = queryResult[1]["GROUP_DESC"];
    record.AVATER_URL  = queryResult[1]["AVATER_URL"];
	
	record.success = true;
	
    return record;
end

_GroupModel.queryGroupById = queryGroupById;
---------------------------------------------------------------------------

return _GroupModel


