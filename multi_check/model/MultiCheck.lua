--[[
#申健 2015-03-09
#描述：资源审核的业务函数类
]]

local resInfoModel    = require "resource.model.ResourceInfo";
local AnalyseService  = require "management.analyse.services.AnalyseDataService";

local _MultiCheck = {};

local fieldTab = {"PROVINCE_ID", "CITY_ID", "DISTRICT_ID", "P_SCHOOL_ID", "C_SCHOOL_ID"};
local StrucService = require "base.structure.services.StructureService";

local function _getCache()
	-- 4.获取redis链接
	local redis = require "resty.redis"
	local cache = redis:new()
	local ok,err = cache:connect(v_redis_ip,v_redis_port)
	if not ok then
		ngx.print("{\"success\":\"false\",\"info\":\""..err.."\"}")
		return false;
	end
	
	return cache;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取查询审核列表时的条件sql语句
	作者：   申健 2015-03-09
	参数：   unitId  		  单位ID
	参数：   unitType  		  单位类型：1省、2市、3区、4总校、5分校
	参数：   sourceUnitId  	  资源的共享人所在的单位ID
	参数：   destUnit  		  共享目标：1共享给当前单位，2共享给上级单位
	参数：   checkStatus      审核状态：00：表示不需要此级审核，    10：表示需要审核，待审核。
                                        11：需要审核，而且审核通过。12:需要审核，而且审核被拒绝。
	参数：   stageId          学段ID，逻辑描述：
                              a、前台人员查看所有科目subjectId=0;
                              b、后台人员查看所有学段subjectId=-1;
                              c、后台管理员查看指定学段下的所有学科：subjectId=-2 and stageId为指定学段的ID
	参数：   subjectId        科目ID
	参数：   personId         审核人员的ID
	参数：   identityId       审核人员的身份
	返回值1：string 条件sql语句
]]
local function _getQueryConditionSql(unitId, unitType, sourceUnitId, destUnit, checkStatus, stageId, subjectId, personId, identityId, sharePersonName)
		
	local conditionSql = "";
	local CheckPerson = require "multi_check.model.CheckPerson";
	
	-- 审核人员在界面中选择指定的单位，审核该单位下教师共享的资源
	if sourceUnitId~=nil and sourceUnitId~=0 then
		local sourceUnitType = CheckPerson:getUnitType(sourceUnitId);
		conditionSql = conditionSql .. " AND T1." .. fieldTab[sourceUnitType] .. "=" .. sourceUnitId;
	else
		conditionSql = conditionSql .. " AND T1." .. fieldTab[unitType] .. "=" .. unitId;
	end
	
	if subjectId == 0 then -- 可审的全部科目
		
		local CheckPerson = require "multi_check.model.CheckPerson";

		local subjectJson = CheckPerson: getSubjectByPerson(unitId, personId, identityId);
		local subjectList = subjectJson.subject_List;
		if #subjectList > 0 then 
			conditionSql = conditionSql .. " AND (";
			for i=1, #subjectList do
				local tempSubjectId = subjectList[i]["SUBJECT_ID"];
				if i==1 then 
					conditionSql = conditionSql .. " T1.SUBJECT_ID=" .. tempSubjectId;
				else
					conditionSql = conditionSql .. " OR T1.SUBJECT_ID=" .. tempSubjectId;
				end
			end
			conditionSql = conditionSql .. ") ";
		else
            conditionSql = conditionSql .. " AND T1.SUBJECT_ID=-1";
        end
	elseif subjectId == -1 then -- 各级管理员在查看列表时如果查看全部学段，则传-1
        
    elseif subjectId == -2 then -- 各级管理员在查看列表时如果查看指定学段下全部学科，则传-2
        conditionSql = conditionSql .. " AND T1.STAGE_ID=" .. stageId;
    else -- 指定单个学科
		conditionSql = conditionSql .. " AND T1.SUBJECT_ID=" .. subjectId;
	end
	
	-- 根据上传人的姓名进行模糊查询
	if sharePersonName ~= nil and sharePersonName ~= "" then
	    conditionSql = conditionSql .. " AND T1.SHARE_PERSON_NAME LIKE '%" .. sharePersonName .."%' ";
	end
	
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 获取审核表，参数：unitId -> ", unitId, type(unitId), ", unitType -> ", unitType, ", sourceUnitId -> ", sourceUnitId, ", destUnit -> ", destUnit, ", checkStatus -> ", checkStatus, type(checkStatus));
	
	-- destUnit : 共享目标：0全部，1共享给当前单位，2共享给上级单位
	if destUnit == 0 then -- 共享目标：全部
		if checkStatus == "0" then -- 审核状态：全部
			
			if unitType == 1 then -- 单位类型：省
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '100%' OR T1.CHECK_PATH LIKE '1011%' OR T1.CHECK_PATH LIKE '11%' OR T1.CHECK_PATH LIKE '12%' OR T1.CHECK_PATH LIKE '10%10%')";
			elseif unitType == 2 then -- 单位类型：市
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '__100%' OR T1.CHECK_PATH LIKE '__1011%' OR T1.CHECK_PATH LIKE '__11%' OR T1.CHECK_PATH LIKE '__12%' OR T1.CHECK_PATH LIKE '0010%10%')";
			elseif unitType == 3 then -- 单位类型：区
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '____100%' OR T1.CHECK_PATH LIKE '____1011%' OR T1.CHECK_PATH LIKE '____11%' OR T1.CHECK_PATH LIKE '____12%' OR T1.CHECK_PATH LIKE '00001010%')";
			elseif unitType == 4 then -- 单位类型：总校
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '%100_' OR T1.CHECK_PATH LIKE '%1011' OR T1.CHECK_PATH LIKE '______1111' OR T1.CHECK_PATH LIKE '______12__' OR T1.CHECK_PATH='0000001010')";
			elseif unitType == 5 then -- 单位类型：分校
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '%1_'";
			end
			
		elseif checkStatus == "10" then -- 审核状态：待审核
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '100%' OR T1.CHECK_PATH LIKE '1011%') ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '__100%' OR T1.CHECK_PATH LIKE '__1011%') ";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '____100%' OR T1.CHECK_PATH LIKE '____1011%') ";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '______100%' OR T1.CHECK_PATH LIKE '______1011') ";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '%10'";
			end
			
		elseif checkStatus == "11" then -- 审核状态：审核通过
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '11%'";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '__11%'";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '____11%'";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '______1111'";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '________11'";
			end
		elseif checkStatus == "12" then -- 审核状态：未通过
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '12%' ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '__12%' ";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '____12%' ";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '______12%' ";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '________12'";
			end
		elseif checkStatus == "20" then -- 审核状态： 下级待审核
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '10%10%' ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '0010%10%' ";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '00001010%' ";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH='0000001010' ";
			elseif unitType == 5 then
				
			end
		end
	elseif destUnit == 1 then -- 共享目标：共享给当前单位
		
		if checkStatus == "0" then -- 审核状态： 全部
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '100%' OR T1.CHECK_PATH LIKE '1011%' OR T1.CHECK_PATH LIKE '11%' OR T1.CHECK_PATH LIKE '120%' OR T1.CHECK_PATH LIKE '1211%' OR T1.CHECK_PATH LIKE '10%10%')";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '00100%' OR T1.CHECK_PATH LIKE '001011%' OR T1.CHECK_PATH LIKE '0011%' OR T1.CHECK_PATH LIKE '00120%' OR T1.CHECK_PATH LIKE '001211%' OR T1.CHECK_PATH LIKE '0010%10%')";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '0000100%' OR T1.CHECK_PATH LIKE '00001011%' OR T1.CHECK_PATH LIKE '000011%' OR T1.CHECK_PATH LIKE '0000120%' OR T1.CHECK_PATH LIKE '00001211%' OR T1.CHECK_PATH LIKE '00001010%')";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '000000100_' OR T1.CHECK_PATH LIKE '%001011' OR T1.CHECK_PATH ='0000001111' OR T1.CHECK_PATH LIKE '000000120_' OR T1.CHECK_PATH='0000001211' OR T1.CHECK_PATH='0000001010')";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH ='0000000010' OR T1.CHECK_PATH ='0000000011' OR T1.CHECK_PATH ='0000000012')";
			end
			
		elseif checkStatus == "10" then -- 审核状态： 待审核
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '100%' OR T1.CHECK_PATH LIKE '1011%')";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '00100%' OR T1.CHECK_PATH LIKE '001011%')";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '0000100%' OR T1.CHECK_PATH LIKE '00001011%')";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '000000100_' OR T1.CHECK_PATH LIKE '%001011')";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH ='0000000010'";
			end
			
		elseif checkStatus == "11" then -- 审核状态： 审核通过
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '11%'";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '0011%'";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '000011%'";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH ='0000001111'";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH ='0000000011'";
			end
		elseif checkStatus == "12" then -- 审核状态： 审核未通过
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '120%' OR T1.CHECK_PATH LIKE '1211%') ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '00120%' OR T1.CHECK_PATH LIKE '001211%') ";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '0000120%' OR T1.CHECK_PATH LIKE '00001211%') ";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '000000120_' OR T1.CHECK_PATH='0000001211') ";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH ='0000000012'";
			end
		elseif checkStatus == "20" then -- 审核状态： 下级待审核
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '10%10%' ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '0010%10%' ";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '00001010%' ";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH='0000001010' ";
			elseif unitType == 5 then
				
			end
		end
	else -- 共享目标： 2 共享给上级单位
		
		if checkStatus == "0" then -- 审核状态： 全部
			
			if unitType == 1 then
				conditionSql = conditionSql .. " AND 1=2 ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '101011%' OR T1.CHECK_PATH LIKE '1_11%' OR T1.CHECK_PATH LIKE '1012%') ";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '__101011__' OR T1.CHECK_PATH LIKE '__1_11%' OR T1.CHECK_PATH LIKE '__1012%') ";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH LIKE '____101011' OR T1.CHECK_PATH LIKE '%1_11__' OR T1.CHECK_PATH LIKE '%1012__') ";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND (T1.CHECK_PATH ='%1010' OR T1.CHECK_PATH LIKE '%1_11' OR T1.CHECK_PATH ='%1012')";
			end
		
		elseif checkStatus == "10" then -- 审核状态：待审核
			if unitType == 1 then
				conditionSql = conditionSql .. " AND 1=2 ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '101011%'";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '__101011__'";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '____101011'";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH ='%1010'";
			end
			
		elseif checkStatus == "11" then -- 审核状态：通过
			if unitType == 1 then
				conditionSql = conditionSql .. " AND 1=2 ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '1_11%'";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '__1_11%'";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '%1_11__'";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '%1_11'";
			end
		elseif checkStatus == "12" then -- 审核状态：未通过
			if unitType == 1 then
				conditionSql = conditionSql .. " AND 1=2 ";
			elseif unitType == 2 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '1012%'";
			elseif unitType == 3 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '__1012%'";
			elseif unitType == 4 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH LIKE '%1012__'";
			elseif unitType == 5 then
				conditionSql = conditionSql .. " AND T1.CHECK_PATH ='%1012'";
			end
		end
	end
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> conditionSql(CHECK_PATH的模糊查询子句) ===> ", conditionSql)
	return conditionSql;
end

---------------------------------------------------------------------------
--[[
	局部函数：根据用户的 PERSON_ID 查找用户锁在机构的名称
	作者：  申健        2015-04-16
	参数：  personId  	人员ID
	参数：  dentityId  	身份ID
	返回值：组织机构名称
]]
local function _getOrgNameByPerson(personId, identityId)
	
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache     = CacheUtil: getRedisConn();
	
	local orgId   = cache: hget("person_" .. personId .. "_" .. identityId, "xiao");
	local orgName = cache: hget("t_base_organization_" .. orgId, "org_name");
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
    
    if orgName == nil or orgName == ngx.null or orgName == "" then
        return "--";
    end
    
    return orgName;
end

---------------------------------------------------------------------------

--[[
	局部函数：查询审核列表
	作者： 申健 2015-03-08
	参数： unitId  		         单位ID
	参数： objType  		     审核的对象：资源类型：1资源，2试题，3试卷，4备课，5微课
	参数： subjectId  		     科目ID
	参数： schemeId  		     版本ID
	参数： sourceUnitId  	     资源的共享人所在的单位ID
	参数： destUnit  		     共享目标：1共享给当前单位，2共享给上级单位
	参数： checkStatus  	     审核状态：00：表示不需要此级审核，10：表示需要审核，待审核。11：需要审核，而且审核通过。12:需要审核，而且审核被拒绝。
	参数： pageNumber  	         请求页数
	参数： pageSize  		     每页显示数据条数
	参数： personId  		     审核人的用户ID，用于获取审核人可以审核的学科
	参数： identityId  	         审核人的身份ID，用于获取审核人可以审核的学科
	参数： sharePersonName 	     共享人的用户名，用于进行按上传人名模糊查询
	参数： recommendStatus 	     推荐状态：0全部，1已推荐，2未推荐
	返回值：isPersonExist        该教师是否为该单位的审核人员：0不是，1是（不考虑设置的科目）
	返回值：isPersonSubjectExist 该教师是否为该单位下指定科目的审核人员：0不是，1是
]]
local function getCheckObjList(self, unitId, objType, stageId, subjectId, schemeId, sourceUnitId, destUnit, checkStatus, pageNumber, pageSize, personId, identityId, sharePersonName, recommendStatus)
	
	local cjson  = require "cjson"; 
	local DBUtil = require "multi_check.model.DBUtil";
	local db     = DBUtil: getDb();
	local cache  = _getCache();
	
	local CheckPath   = require "multi_check.model.CheckPath";
	local CheckPerson = require "multi_check.model.CheckPerson";
	-- 单位类型：1省、2市、3区、4总校、5分校
	local unitType    = CheckPerson:getUnitType(unitId);
	
	local conditionSql = "";
	
	-- 如果用户选择了某个版本
	-- if schemeId~=0 then
		-- conditionSql = conditionSql .. " AND T1.SCHEME_ID=" .. schemeId;
	-- else
		-- conditionSql = conditionSql .. " AND T1.SUBJECT_ID=" .. subjectId;
	-- end
	local orderSegement = "";
	local endOrderSegement = "";
	local joinWay = "";
	local recommendSegement = "";

	if recommendStatus == 0 then -- 推荐状态：0全部，1已推荐，2未推荐
		joinWay = "LEFT OUTER JOIN";
		orderSegement = " ORDER BY T1.ID DESC ";
		endOrderSegement = "ORDER BY TEMP.CHECK_ID DESC ";
	elseif recommendStatus == 1 then 
		joinWay = "INNER JOIN";
		orderSegement = " ORDER BY CR.SORT_TS DESC ";
		endOrderSegement = "ORDER BY TEMP.SORT_TS DESC ";
	elseif recommendStatus == 2 then
		joinWay = "LEFT OUTER JOIN";
		recommendSegement = " AND CR.ID IS NULL"
		orderSegement = " ORDER BY T1.ID DESC ";
		endOrderSegement = "ORDER BY TEMP.CHECK_ID DESC ";
	end

	conditionSql = conditionSql .. _getQueryConditionSql(unitId, unitType, sourceUnitId, destUnit, checkStatus, stageId, subjectId, personId, identityId, sharePersonName);
	
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_BASE_CHECK_INFO T1 ".. joinWay .. " T_BASE_CHECK_RECOMMEND CR ON T1.OBJ_TYPE=CR.OBJ_TYPE AND T1.OBJ_ID_INT=CR.OBJ_ID_INT AND CR.ORG_ID = " .. unitId .. " WHERE T1.OBJ_TYPE=" .. objType .. conditionSql .. recommendSegement .. ";";
	ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> 查询审核列表总数的sql语句：[[[", countSql, "]]]");
    local res, err, errno, sqlstate = db:query(countSql);
    if not res then
        return {success=false, info="查询数据出错。"};
    end
	local totalRow  = res[1]["TOTAL_ROW"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	local offset    = pageSize*pageNumber-pageSize;
	local limit     = pageSize;

	local resArray  = {};
	
    if objType == 1 or objType == 4 then -- 资源类型：1资源，2试题，3试卷，4备课，5微课
        local resInfoModel = require "resource.model.ResourceInfo";

        local sql = "SELECT TEMP.*, T2.ID, T2.RESOURCE_TITLE, T2.RESOURCE_TYPE_NAME, T2.RESOURCE_FORMAT, T2.FILE_ID, T2.PREVIEW_STATUS, T2.FOR_ISO_URL, T2.FOR_URLENCODER_URL, T2.WIDTH, T2.HEIGHT, T2.RESOURCE_SIZE, T2.RESOURCE_PAGE, T2.APP_TYPE_ID, T2.RES_TYPE, T2.BK_TYPE, T2.BK_TYPE_NAME FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_TYPE, T1.CHECK_PATH, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, T1.STAGE_ID, T1.SUBJECT_ID, T1.SCHEME_ID, CR.ID AS RECOMMEND_ID, CR.OBJ_INFO_ID, CR.SORT_TS, CR.B_TOP FROM T_BASE_CHECK_INFO T1 " .. joinWay .. " T_BASE_CHECK_RECOMMEND CR ON T1.OBJ_TYPE=CR.OBJ_TYPE AND T1.OBJ_ID_INT=CR.OBJ_ID_INT AND CR.ORG_ID = " .. unitId .. " WHERE T1.OBJ_TYPE=" .. objType .. conditionSql .. recommendSegement .. orderSegement .. " LIMIT " .. offset .. "," .. limit .. ") AS TEMP INNER JOIN T_RESOURCE_INFO T2 WHERE TEMP.OBJ_ID_INT = T2.RESOURCE_ID_INT AND T2.GROUP_ID=2 " .. endOrderSegement .. ";"; 
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询审核列表 sql ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
            return;
        end

        for i=1, #res do
        
            local structurePath = StrucService: getStrucPath(res[i]["STRUCTURE_ID"])
            
            local record = {};
            record.iid 			         = res[i]["ID"];
            record.obj_id_int 			 = res[i]["OBJ_ID_INT"];
            record.obj_type              = res[i]["OBJ_TYPE"];
            record.check_id 		     = res[i]["CHECK_ID"];
            record.check_path 		     = res[i]["CHECK_PATH"];
            record.check_status 	     = res[i]["CHECK_STATUS"];
            record.stage_id  	 	     = res[i]["STAGE_ID"];
            record.subject_id	 	     = res[i]["SUBJECT_ID"];
            record.structure_id		     = res[i]["STRUCTURE_ID"];
            record.create_time		     = res[i]["CREATE_TIME"];
            record.share_person_id     	 = res[i]["SHARE_PERSON_ID"];
            record.share_person_name     = res[i]["SHARE_PERSON_NAME"];
            record.province_id  	     = res[i]["PROVINCE_ID"];
            record.city_id 			     = res[i]["CITY_ID"];
            record.district_id  	     = res[i]["DISTRICT_ID"];
            record.p_school_id		     = res[i]["P_SCHOOL_ID"];
            record.c_school_id		     = res[i]["C_SCHOOL_ID"];
            record.parent_structure_name = structurePath;
            record.resource_title 	  	 = res[i]["RESOURCE_TITLE"];
            record.resource_type_name    = res[i]["RESOURCE_TYPE_NAME"];
            record.resource_format 	     = res[i]["RESOURCE_FORMAT"];
            record.url_code 	  	     = ngx.escape_uri(record.resource_title);
            record.file_id	 	  	     = res[i]["FILE_ID"];
            record.preview_status 	     = res[i]["PREVIEW_STATUS"];
            record.for_iso_url 	  	     = res[i]["FOR_ISO_URL"];
            record.for_urlencoder_url    = res[i]["FOR_URLENCODER_URL"];
            record.width	 	  	     = res[i]["WIDTH"];
            record.height	 	  	     = res[i]["HEIGHT"];
            record.resource_size  	     = res[i]["RESOURCE_SIZE"];
            record.resource_page  	     = res[i]["RESOURCE_PAGE"];
            record.app_type_id  	     = res[i]["APP_TYPE_ID"];
            record.app_type_name  	     = resInfoModel: getAppTypeName(record.app_type_id, res[i]["SCHEME_ID"]);
            record.res_type  	         = res[i]["RES_TYPE"];
            record.bk_type  	         = res[i]["BK_TYPE"];
            record.bk_type_name  	     = res[i]["BK_TYPE_NAME"];
            record.recommend_id  	     = res[i]["RECOMMEND_ID"];
            record.obj_info_id  	     = res[i]["OBJ_INFO_ID"];
            record.sort_ts       	     = res[i]["SORT_TS"];
            record.b_top       	         = res[i]["B_TOP"];
            local pathBean = CheckPath: new(unitId, record.check_path);
            record.can_modify			 = pathBean: canModifyStatus();
            record.current_status		 = pathBean: getCurrentLevelStatus();
			local destLevel, currentLevel= pathBean: getDestUnit();
            record.dest_unit			 = res[i][fieldTab[destLevel]];
            record.now_status            = pathBean:getNowCheckLevelAndState();
            if record.dest_unit == unitId then
                record.can_delete = true;
            else
                record.can_delete = false;
            end
            record.can_supersedeCheck    = pathBean: canSupersedeCheck();
            record.current_unit			 = res[i][fieldTab[currentLevel]];
            record.share_person_unit     = _getOrgNameByPerson(record.share_person_id, 5);
            
            table.insert(resArray, record);
        end
    elseif objType == 2 then -- 试题
		
		local sql = "SELECT TEMP.*, T2.ID, T2.QUESTION_ID_CHAR, T2.JSON_QUESTION FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_ID_CHAR, T1.OBJ_TYPE, T1.CHECK_PATH, T1.STAGE_ID, T1.SUBJECT_ID, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, T1.SCHEME_ID FROM T_BASE_CHECK_INFO T1 WHERE T1.OBJ_TYPE=" .. objType .. conditionSql .. " ORDER BY T1.ID DESC LIMIT " .. offset .. "," .. limit .. ") AS TEMP INNER JOIN T_TK_QUESTION_INFO T2 ON TEMP.OBJ_ID_CHAR = T2.QUESTION_ID_CHAR AND T2.OPER_TYPE=1 AND T2.GROUP_ID=2 AND TEMP.STRUCTURE_ID = T2.STRUCTURE_ID_INT AND T2.B_IN_PAPER=0 ORDER BY TEMP.CHECK_ID DESC;";
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询审核列表(试题) sql ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
            return;
        end

        for i=1, #res do
        
            local structurePath = StrucService: getStrucPath(res[i]["STRUCTURE_ID"])
            
            local record = {};
            record.id 			         = res[i]["ID"];
            record.obj_id_char 			 = res[i]["OBJ_ID_CHAR"];
            record.obj_type               = res[i]["OBJ_TYPE"];
            record.check_id 		     = res[i]["CHECK_ID"];
            record.check_path 		     = res[i]["CHECK_PATH"];
            record.stage_id  	 	     = res[i]["STAGE_ID"];
            record.subject_id		     = res[i]["SUBJECT_ID"];
            record.structure_id		     = res[i]["STRUCTURE_ID"];
            record.create_time		     = res[i]["CREATE_TIME"];
			record.share_person_id     	 = res[i]["SHARE_PERSON_ID"];
            record.share_person_name     = res[i]["SHARE_PERSON_NAME"];
            record.province_id  	     = res[i]["PROVINCE_ID"];
            record.city_id 			     = res[i]["CITY_ID"];
            record.district_id  	     = res[i]["DISTRICT_ID"];
            record.p_school_id		     = res[i]["P_SCHOOL_ID"];
            record.c_school_id		     = res[i]["C_SCHOOL_ID"];
            record.parent_structure_name = structurePath;
            local pathBean = CheckPath: new(unitId, record.check_path);
            record.can_modify			 = pathBean: canModifyStatus();
            record.current_status		 = pathBean: getCurrentLevelStatus();
			local destLevel, currentLevel= pathBean: getDestUnit();
            record.dest_unit			 = res[i][fieldTab[destLevel]];
            record.current_unit			 = res[i][fieldTab[currentLevel]];
            record.now_status            = pathBean:getNowCheckLevelAndState();
            if record.dest_unit == unitId then
                record.can_delete = true;
            else
                record.can_delete = false;
            end
            record.can_supersedeCheck    = pathBean: canSupersedeCheck();
            record.share_person_unit     = _getOrgNameByPerson(record.share_person_id, 5);
            
            local jsonQuesBase64 = res[i]["JSON_QUESTION"];
            local jsonQuesStr    = ngx.decode_base64(jsonQuesBase64);
            local jsonQuesObj    = cjson.decode(jsonQuesStr);
            record.json_question = jsonQuesObj;

            table.insert(resArray, record);
        end
    elseif objType == 3 then -- 试卷
        
        local sql = "SELECT TEMP.*, T2.ID, T2.PAPER_ID_INT, T2.PAPER_ID_CHAR, T2.PAPER_NAME, T2.PAPER_TYPE, T2.QUESTION_COUNT, T2.SOURCE_ID, T3.PARENT_STRUCTURE_NAME, T3.RESOURCE_TYPE_NAME, T3.RESOURCE_FORMAT, T3.FILE_ID, T3.PREVIEW_STATUS, T3.FOR_ISO_URL, T3.FOR_URLENCODER_URL, T3.RESOURCE_SIZE, T3.RESOURCE_PAGE FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_TYPE, T1.CHECK_PATH, T1.STAGE_ID, T1.SUBJECT_ID, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, T1.SCHEME_ID, CR.ID AS RECOMMEND_ID, CR.OBJ_INFO_ID, CR.SORT_TS, CR.B_TOP FROM T_BASE_CHECK_INFO T1 " .. joinWay .. " T_BASE_CHECK_RECOMMEND CR ON T1.OBJ_TYPE=CR.OBJ_TYPE AND T1.OBJ_ID_INT=CR.OBJ_ID_INT AND CR.ORG_ID = " .. unitId .. " WHERE T1.OBJ_TYPE=" .. objType .. conditionSql .. recommendSegement .. orderSegement .. " LIMIT " .. offset .. "," .. limit .. ") AS TEMP INNER JOIN T_SJK_PAPER_INFO T2 ON TEMP.OBJ_ID_INT = T2.PAPER_ID_INT AND T2.GROUP_ID=2 LEFT OUTER JOIN T_RESOURCE_INFO T3 ON T2.RESOURCE_INFO_ID=T3.ID AND T3.ID > 0 " .. endOrderSegement .. ";";
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询审核列表(试卷) sql ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
            return;
        end

        for i=1, #res do
        
            local structurePath = StrucService: getStrucPath(res[i]["STRUCTURE_ID"])
            
            local record = {};
            record.iid 			         = res[i]["ID"];
            record.obj_id_int 			 = res[i]["OBJ_ID_INT"];
            record.obj_type               = res[i]["OBJ_TYPE"];
            record.check_id 		     = res[i]["CHECK_ID"];
            record.check_path 		     = res[i]["CHECK_PATH"];
            record.stage_id  	 	     = res[i]["STAGE_ID"];
            record.subject_id		     = res[i]["SUBJECT_ID"];
            record.structure_id		     = res[i]["STRUCTURE_ID"];
            record.create_time		     = res[i]["CREATE_TIME"];
			record.share_person_id     	 = res[i]["SHARE_PERSON_ID"];
            record.share_person_name     = res[i]["SHARE_PERSON_NAME"];
            record.province_id  	     = res[i]["PROVINCE_ID"];
            record.city_id 			     = res[i]["CITY_ID"];
            record.district_id  	     = res[i]["DISTRICT_ID"];
            record.p_school_id		     = res[i]["P_SCHOOL_ID"];
            record.c_school_id		     = res[i]["C_SCHOOL_ID"];
            record.parent_structure_name = structurePath;
            record.paper_id_int  	     = res[i]["PAPER_ID_INT"];
            record.paper_id_char  	     = res[i]["PAPER_ID_CHAR"];
            record.paper_name	 	  	 = res[i]["PAPER_NAME"];
            record.ti_num		 	  	 = res[i]["QUESTION_COUNT"];			
            record.extenstion	 	     = res[i]["RESOURCE_FORMAT"];
            record.url_code 	  	     = ngx.escape_uri(record.paper_name);
            record.file_id	 	  	     = res[i]["FILE_ID"];
            record.preview_status 	     = res[i]["PREVIEW_STATUS"];
            record.for_iso_url 	  	     = res[i]["FOR_ISO_URL"];
            record.for_urlencoder_url    = res[i]["FOR_URLENCODER_URL"];
            record.paper_source  	     = res[i]["PAPER_TYPE"];
            record.page  	     		 = res[i]["RESOURCE_PAGE"];
            local pathBean = CheckPath: new(unitId, record.check_path);
            record.can_modify			 = pathBean: canModifyStatus();
            record.current_status		 = pathBean: getCurrentLevelStatus();
			local destLevel, currentLevel= pathBean: getDestUnit();
            record.dest_unit			 = res[i][fieldTab[destLevel]];
            record.current_unit			 = res[i][fieldTab[currentLevel]];
            record.now_status            = pathBean:getNowCheckLevelAndState();
            if record.dest_unit == unitId then
                record.can_delete = true;
            else
                record.can_delete = false;
            end
            record.can_supersedeCheck    = pathBean: canSupersedeCheck();
            record.share_person_unit     = _getOrgNameByPerson(record.share_person_id, 5);
            record.recommend_id  	     = res[i]["RECOMMEND_ID"];
            record.obj_info_id  	     = res[i]["OBJ_INFO_ID"];
            record.sort_ts       	     = res[i]["SORT_TS"];
            record.b_top       	         = res[i]["B_TOP"];
            
            table.insert(resArray, record);
        end
    elseif objType == 5 then -- 微课
        
        local sql = "SELECT TEMP.*, T2.ID, T2.WKDS_ID_INT, T2.WKDS_NAME, T2.TEACHER_NAME, T2.WK_TYPE, T2.WK_TYPE_NAME FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_TYPE, T1.CHECK_PATH, T1.STAGE_ID, T1.SUBJECT_ID, T1.SCHEME_ID, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, CR.ID AS RECOMMEND_ID, CR.OBJ_INFO_ID, CR.SORT_TS, CR.B_TOP FROM T_BASE_CHECK_INFO T1 " .. joinWay .. " T_BASE_CHECK_RECOMMEND CR ON T1.OBJ_TYPE=CR.OBJ_TYPE AND T1.OBJ_ID_INT=CR.OBJ_ID_INT AND CR.ORG_ID = " .. unitId .. " WHERE T1.OBJ_TYPE=" .. objType .. conditionSql .. recommendSegement .. orderSegement .. " LIMIT " .. offset .. "," .. limit .. ") AS TEMP INNER JOIN T_WKDS_INFO T2 ON TEMP.OBJ_ID_INT=T2.WKDS_ID_INT AND T2.TYPE=1 AND T2.GROUP_ID=2 " .. endOrderSegement .. ";";
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询审核列表(微课) sql ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
            return;
        end

        for i=1, #res do
        
            local structurePath = StrucService: getStrucPath(res[i]["STRUCTURE_ID"])
            
            local record = {};
            record.id 			         = res[i]["ID"];
            record.obj_id_int 			 = res[i]["OBJ_ID_INT"];
            record.obj_type               = res[i]["OBJ_TYPE"];
            record.check_id 		     = res[i]["CHECK_ID"];
            record.check_path 		     = res[i]["CHECK_PATH"];
            record.stage_id  	 	     = res[i]["STAGE_ID"];
            record.subject_id		     = res[i]["SUBJECT_ID"];
            record.structure_id		     = res[i]["STRUCTURE_ID"];
            record.create_time		     = res[i]["CREATE_TIME"];
			record.share_person_id     	 = res[i]["SHARE_PERSON_ID"];
            record.share_person_name     = res[i]["SHARE_PERSON_NAME"];
            record.province_id  	     = res[i]["PROVINCE_ID"];
            record.city_id 			     = res[i]["CITY_ID"];
            record.district_id  	     = res[i]["DISTRICT_ID"];
            record.p_school_id		     = res[i]["P_SCHOOL_ID"];
            record.c_school_id		     = res[i]["C_SCHOOL_ID"];
            record.parent_structure_name = structurePath;
            record.wkds_id_int			 = res[i]["WKDS_ID_INT"];
            record.wkds_name			 = res[i]["WKDS_NAME"];
            record.teacher_name			 = res[i]["TEACHER_NAME"];
            record.wk_type			     = res[i]["WK_TYPE"];
            record.wk_type_name		     = res[i]["WK_TYPE_NAME"];			
            local pathBean = CheckPath: new(unitId, record.check_path);
            record.can_modify			 = pathBean: canModifyStatus();
            record.current_status		 = pathBean: getCurrentLevelStatus();
			local destLevel, currentLevel= pathBean: getDestUnit();
            record.dest_unit			 = res[i][fieldTab[destLevel]];
            record.current_unit			 = res[i][fieldTab[currentLevel]];
            record.now_status            = pathBean:getNowCheckLevelAndState();
            if record.dest_unit == unitId then
                record.can_delete = true;
            else
                record.can_delete = false;
            end
            record.can_supersedeCheck    = pathBean: canSupersedeCheck();
            record.share_person_unit     = _getOrgNameByPerson(record.share_person_id, 5);
            record.recommend_id  	     = res[i]["RECOMMEND_ID"];
            record.obj_info_id  	     = res[i]["OBJ_INFO_ID"];
            record.sort_ts       	     = res[i]["SORT_TS"];
            record.b_top       	         = res[i]["B_TOP"];

            table.insert(resArray, record);
        end
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
	-- 将redis连接归还到连接池
	local ok, err = cache: set_keepalive(0, v_pool_size)
	if not ok then
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 将Redis连接归还连接池出错！");
	end
	return resListJson;
end

_MultiCheck.getCheckObjList = getCheckObjList;


---------------------------------------------------------------------------
--[[
	局部函数：获取下一条审核记录
	作者： 申健 2015-03-08
	参数： unitId  			单位ID
	参数： objType  		审核的对象：资源类型：1资源，2试题，3试卷，4备课，5微课
	参数： subjectId  		科目ID
	参数： schemeId  		版本ID
	参数： sourceUnitId  	资源的共享人所在的单位ID
	参数： destUnit  		共享目标：1共享给当前单位，2共享给上级单位
	参数： checkStatus  	审核状态：00：表示不需要此级审核，10：表示需要审核，待审核。11：需要审核，而且审核通过。12:需要审核，而且审核被拒绝。
	参数： pageNumber  		请求页数
	参数： pageSize  		每页显示数据条数
	返回值：isPersonExist 该教师是否为该单位的审核人员：0不是，1是（不考虑设置的科目）
	返回值：isPersonSubjectExist 该教师是否为该单位下指定科目的审核人员：0不是，1是
]]
local function getNextCheckInfo(self, unitId, objType, stageId, subjectId, schemeId, sourceUnitId, destUnit, checkStatus, checkId, personId, identityId)
	
	local cjson = require "cjson";
	local CheckPerson = require "multi_check.model.CheckPerson";
	local DBUtil 	  = require "multi_check.model.DBUtil";
	local db 	= DBUtil: getDb();
	local cache = _getCache();
	
	-- 单位类型：1省、2市、3区、4总校、5分校
	local unitType = CheckPerson:getUnitType(unitId);
	
	local conditionSql = "";
	
	-- 如果用户选择了某个版本
	-- if schemeId~=0 then
		-- conditionSql = conditionSql .. " AND T1.SCHEME_ID=" .. schemeId;
	-- else
		-- conditionSql = conditionSql .. " AND T1.SUBJECT_ID=" .. subjectId;
	-- end
	
	conditionSql = conditionSql .. _getQueryConditionSql(unitId, unitType, sourceUnitId, destUnit, checkStatus, stageId, subjectId, personId, identityId);
	
	local countSql = "SELECT COUNT(1) AS TOTAL_ROW FROM (SELECT T1.ID FROM T_BASE_CHECK_INFO T1 WHERE T1.OBJ_TYPE=" .. objType .. " AND T1.ID < " .. checkId .. " ".. conditionSql .. " LIMIT 1) AS TEMP_CHECK_INFO ;";
        
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 判断是否有下一条审核记录的SQL语句 ===> ", countSql);
    
    local countRes, err, errno, sqlstate = db:query(countSql);
    if not countRes then
        return false, "查询数据出错。";
    end
    
    local totalRow = tonumber(countRes[1]["TOTAL_ROW"]);
    if totalRow == 0 then
        return false, "没有下一条数据。";
    end


	local record = {};
	
    if objType == 1 or objType == 4 then -- 资源类型：1资源，2试题，3试卷，4备课，5微课
        local sql = "SELECT TEMP.*, T2.ID, T2.RESOURCE_TITLE, T2.RESOURCE_TYPE_NAME, T2.RESOURCE_FORMAT, T2.FILE_ID, T2.PREVIEW_STATUS, T2.FOR_ISO_URL, T2.FOR_URLENCODER_URL, T2.WIDTH, T2.HEIGHT, T2.RESOURCE_SIZE, T2.RESOURCE_PAGE, T2.APP_TYPE_ID, T2.RES_TYPE, T2.BK_TYPE, T2.BK_TYPE_NAME FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_TYPE, T1.CHECK_PATH, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, T1.SUBJECT_ID, T1.SCHEME_ID FROM T_BASE_CHECK_INFO T1 WHERE T1.OBJ_TYPE=" .. objType .. " AND T1.ID < " .. checkId .. " " .. conditionSql .. " ORDER BY T1.ID DESC LIMIT 1) AS TEMP INNER JOIN T_RESOURCE_INFO T2 WHERE TEMP.OBJ_ID_INT = T2.RESOURCE_ID_INT AND T2.GROUP_ID=2;";
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 获取下一条审核记录的SQL语句 ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
            return false, "查询数据出错。";
        end
        
        record.iid 			     	 = res[1]["ID"];
        record.check_id 		     = res[1]["CHECK_ID"];
        record.check_path 		     = res[1]["CHECK_PATH"];
        record.check_status 	     = res[1]["CHECK_STATUS"];
        record.structure_id		     = res[1]["STRUCTURE_ID"];
        record.create_time		     = res[1]["CREATE_TIME"];
		record.share_person_id     	 = res[1]["SHARE_PERSON_ID"];
        record.share_person_name     = res[1]["SHARE_PERSON_NAME"];
        record.province_id  	     = res[1]["PROVINCE_ID"];
        record.city_id 			     = res[1]["CITY_ID"];
        record.district_id  	     = res[1]["DISTRICT_ID"];
        record.p_school_id		     = res[1]["P_SCHOOL_ID"];
        record.c_school_id		     = res[1]["C_SCHOOL_ID"];
        record.parent_structure_name = structurePath;
        record.resource_title 	  	 = res[1]["RESOURCE_TITLE"];
        record.resource_type_name    = res[1]["RESOURCE_TYPE_NAME"];
        record.resource_format 	     = res[1]["RESOURCE_FORMAT"];
        record.url_code 	  	     = ngx.escape_uri(record.resource_title);
        record.file_id	 	  	     = res[1]["FILE_ID"];
        record.preview_status 	     = res[1]["PREVIEW_STATUS"];
        record.for_iso_url 	  	     = res[1]["FOR_ISO_URL"];
        record.for_urlencoder_url    = res[1]["FOR_URLENCODER_URL"];
        record.width	 	  	     = res[1]["WIDTH"];
        record.height	 	  	     = res[1]["HEIGHT"];
        record.resource_size  	     = res[1]["RESOURCE_SIZE"];
        record.resource_page  	     = res[1]["RESOURCE_PAGE"];
        record.app_type_id  	     = res[1]["APP_TYPE_ID"];
        record.app_type_name  	     = resInfoModel: getAppTypeName(record.app_type_id, res[1]["SCHEME_ID"]);
        record.res_type  	         = res[1]["RES_TYPE"];
        record.bk_type  	         = res[1]["BK_TYPE"];
        record.bk_type_name  	     = res[1]["BK_TYPE_NAME"];
        
    elseif objType == 2 then -- 试题
    	local sql = "SELECT TEMP.*, T2.ID, T2.QUESTION_ID_CHAR, T2.JSON_QUESTION FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_ID_CHAR, T1.OBJ_TYPE, T1.CHECK_PATH, T1.SUBJECT_ID, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, T1.SCHEME_ID FROM T_BASE_CHECK_INFO T1 WHERE T1.OBJ_TYPE=" .. objType .. " AND T1.ID < " .. checkId .. " " .. conditionSql .. " ORDER BY T1.ID DESC LIMIT 1) AS TEMP INNER JOIN T_TK_QUESTION_INFO T2 ON TEMP.OBJ_ID_CHAR = T2.QUESTION_ID_CHAR AND T2.OPER_TYPE=1 AND T2.GROUP_ID=2 AND TEMP.STRUCTURE_ID = T2.STRUCTURE_ID_INT AND T2.B_IN_PAPER=0;";
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 获取下一条审核记录(*试题*)的SQL语句 ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
            return false, "查询数据出错。";
        end
            
        record.id 			         = res[1]["ID"];
        record.check_id 		     = res[1]["CHECK_ID"];
        record.check_path 		     = res[1]["CHECK_PATH"];
        record.subject_id		     = res[1]["SUBJECT_ID"];
        record.structure_id		     = res[1]["STRUCTURE_ID"];
        record.create_time		     = res[1]["CREATE_TIME"];
		record.share_person_id     	 = res[1]["SHARE_PERSON_ID"];
        record.share_person_name     = res[1]["SHARE_PERSON_NAME"];
        record.province_id  	     = res[1]["PROVINCE_ID"];
        record.city_id 			     = res[1]["CITY_ID"];
        record.district_id  	     = res[1]["DISTRICT_ID"];
        record.p_school_id		     = res[1]["P_SCHOOL_ID"];
        record.c_school_id		     = res[1]["C_SCHOOL_ID"];
        record.parent_structure_name = structurePath;
        record.share_person_unit     = _getOrgNameByPerson(record.share_person_id, 5);
        
        local jsonQuesBase64 = res[1]["JSON_QUESTION"];
        local jsonQuesStr    = ngx.decode_base64(jsonQuesBase64);
        local jsonQuesObj    = cjson.decode(jsonQuesStr);
        record.json_question = jsonQuesObj;

    elseif objType == 3 then -- 试卷
         local sql = "SELECT TEMP.*, T2.ID, T2.PAPER_ID_INT, T2.PAPER_ID_CHAR, T2.PAPER_NAME, T2.PAPER_TYPE, T2.QUESTION_COUNT, T2.SOURCE_ID, T3.PARENT_STRUCTURE_NAME, T3.RESOURCE_TYPE_NAME, T3.RESOURCE_FORMAT, T3.FILE_ID, T3.PREVIEW_STATUS, T3.FOR_ISO_URL, T3.FOR_URLENCODER_URL, T3.RESOURCE_SIZE, T3.RESOURCE_PAGE FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_TYPE, T1.CHECK_PATH, T1.SUBJECT_ID, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID, T1.SCHEME_ID FROM T_BASE_CHECK_INFO T1 WHERE T1.OBJ_TYPE=" .. objType .. " AND T1.ID<" .. checkId .. " " .. conditionSql .. " ORDER BY T1.ID DESC LIMIT 1) AS TEMP INNER JOIN T_SJK_PAPER_INFO T2 ON TEMP.OBJ_ID_INT = T2.PAPER_ID_INT AND T2.GROUP_ID=2 LEFT OUTER JOIN T_RESOURCE_INFO T3 ON T2.RESOURCE_INFO_ID=T3.ID AND T3.ID > 0;";

        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 获取下一条审核记录(*试卷*)的SQL语句 ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
            return false, "查询数据出错。";
        end
        
		record.iid 			         = res[1]["ID"];
		record.check_id 		     = res[1]["CHECK_ID"];
		record.check_path 		     = res[1]["CHECK_PATH"];
		record.structure_id		     = res[1]["STRUCTURE_ID"];
		record.create_time		     = res[1]["CREATE_TIME"];
		record.share_person_id     	 = res[1]["SHARE_PERSON_ID"];
        record.share_person_name     = res[1]["SHARE_PERSON_NAME"];
		record.province_id  	     = res[1]["PROVINCE_ID"];
		record.city_id 			     = res[1]["CITY_ID"];
		record.district_id  	     = res[1]["DISTRICT_ID"];
		record.p_school_id		     = res[1]["P_SCHOOL_ID"];
		record.c_school_id		     = res[1]["C_SCHOOL_ID"];
		record.parent_structure_name = structurePath;
		record.paper_id_int  	     = res[1]["PAPER_ID_INT"];
		record.paper_id_char  	     = res[1]["PAPER_ID_CHAR"];
		record.paper_name	 	  	 = res[1]["PAPER_NAME"];
		record.ti_num		 	  	 = res[1]["QUESTION_COUNT"];			
		record.extenstion	 	     = res[1]["RESOURCE_FORMAT"];
		record.url_code 	  	     = ngx.escape_uri(record.paper_name);
		record.file_id	 	  	     = res[1]["FILE_ID"];
		record.preview_status 	     = res[1]["PREVIEW_STATUS"];
		record.for_iso_url 	  	     = res[1]["FOR_ISO_URL"];
		record.for_urlencoder_url    = res[1]["FOR_URLENCODER_URL"];
		record.paper_source  	     = res[1]["SOURCE_ID"];
		record.page  	     		 = res[1]["RESOURCE_PAGE"];
        
    elseif objType == 5 then -- 微课
        local sql = "SELECT TEMP.*, T2.ID, T2.WKDS_ID_INT, T2.WKDS_NAME, T2.TEACHER_NAME, T2.WK_TYPE, T2.WK_TYPE_NAME FROM (SELECT T1.ID AS CHECK_ID, T1.OBJ_ID_INT, T1.OBJ_TYPE, T1.CHECK_PATH, T1.SUBJECT_ID, T1.SCHEME_ID, T1.STRUCTURE_ID, DATE_FORMAT(T1.CREATE_TIME,'%Y-%m-%d %H:%i:%s') AS CREATE_TIME, T1.SHARE_PERSON_ID, T1.SHARE_PERSON_NAME, T1.PROVINCE_ID, T1.CITY_ID, T1.DISTRICT_ID, T1.P_SCHOOL_ID, T1.C_SCHOOL_ID FROM T_BASE_CHECK_INFO T1 WHERE T1.OBJ_TYPE=" .. objType .. " AND T1.ID<" .. checkId .. conditionSql .. " ORDER BY T1.ID DESC LIMIT 1) AS TEMP INNER JOIN T_WKDS_INFO T2 ON TEMP.OBJ_ID_INT=T2.WKDS_ID_INT AND T2.TYPE=1 AND T2.GROUP_ID=2;";
        
        ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 获取下一条审核记录(*微课*)的SQL语句 ===> ", sql);
        
        local res, err, errno, sqlstate = db:query(sql);
        if not res then
            ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 查询数据出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
            return false, "查询数据出错。";
        end
        
		local structurePath = StrucService: getStrucPath(res[1]["STRUCTURE_ID"])
		record.id 			         = res[1]["ID"];
		record.check_id 		     = res[1]["CHECK_ID"];
		record.check_path 		     = res[1]["CHECK_PATH"];
		record.subject_id		     = res[1]["SUBJECT_ID"];
		record.structure_id		     = res[1]["STRUCTURE_ID"];
		record.create_time		     = res[1]["CREATE_TIME"];
		record.share_person_id     	 = res[1]["SHARE_PERSON_ID"];
        record.share_person_name     = res[1]["SHARE_PERSON_NAME"];
		record.province_id  	     = res[1]["PROVINCE_ID"];
		record.city_id 			     = res[1]["CITY_ID"];
		record.district_id  	     = res[1]["DISTRICT_ID"];
		record.p_school_id		     = res[1]["P_SCHOOL_ID"];
		record.c_school_id		     = res[1]["C_SCHOOL_ID"];
		record.parent_structure_name = structurePath;
		record.wkds_id_int			 = res[1]["WKDS_ID_INT"];
		record.wkds_name			 = res[1]["WKDS_NAME"];
		record.teacher_name			 = res[1]["TEACHER_NAME"];
		record.wk_type			     = res[1]["WK_TYPE"];
		record.wk_type_name		     = res[1]["WK_TYPE_NAME"];			
    end
		
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	-- 将redis连接归还到连接池
	local ok, err = cache: set_keepalive(0, v_pool_size)
	if not ok then
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 将Redis连接归还连接池出错！");
	end
	return true, record;
end

_MultiCheck.getNextCheckInfo = getNextCheckInfo;

---------------------------------------------------------------------------
--[[
	局部函数：获取审核通过后需要向T_RESOURCE_INFO表插入记录的sql语句和缓存对象
	参数：p_resInfoId 	 原始记录的在T_RESOURCE_INFO表的ID
	参数：p_unitId   	 审核人所在单位的ID
]]

local function _getResInfoInsertSqlAndCache(p_resIdInt, p_unitId, p_objType)
	
	local resInfoId = resInfoModel.getInfoId(p_resIdInt);
	
	local p_myTs      = require "resty.TS"
	local p_currentTS = p_myTs.getTs();
	local newInfoId   = resInfoModel.getNewRecordPk();
	-- ngx.log(ngx.ERR, "===> newInfoId ===> ", newInfoId);
	-- 判断资源是否已经存在
	local isExist = resInfoModel.isRecordExist(p_resIdInt, p_unitId);
	
	if not isExist then
	
		local sql = "INSERT INTO t_resource_info(ID, RESOURCE_ID_INT, RESOURCE_ID_CHAR, RESOURCE_TITLE, RESOURCE_TYPE_NAME, RESOURCE_FORMAT, RESOURCE_PAGE, RESOURCE_SIZE, RESOURCE_SIZE_INT, CREATE_TIME, DOWN_COUNT, FILE_ID, THUMB_ID, RESOURCE_TYPE, STRUCTURE_ID, PERSON_ID, PERSON_NAME, IDENTITY_ID, GROUP_ID, PREVIEW_STATUS, SCHEME_ID_INT, TS, THUMB_STATUS, UPDATE_TS, FOR_URLEncoder_Url, FOR_ISO_Url, WIDTH, HEIGHT, PARENT_STRUCTURE_NAME, RELEASE_STATUS, RES_TYPE, BK_TYPE, BK_TYPE_NAME, MATERIAL_TYPE, M3U8_STATUS, M3U8_URL, APP_TYPE_ID, STAGE_ID, SUBJECT_ID, IS_SECONDARY) SELECT ".. newInfoId .." AS ID, RESOURCE_ID_INT, RESOURCE_ID_CHAR, RESOURCE_TITLE, RESOURCE_TYPE_NAME, RESOURCE_FORMAT, RESOURCE_PAGE, RESOURCE_SIZE, RESOURCE_SIZE_INT, CREATE_TIME, DOWN_COUNT, FILE_ID, THUMB_ID, RESOURCE_TYPE, STRUCTURE_ID, PERSON_ID, PERSON_NAME, IDENTITY_ID, " .. p_unitId .. ", PREVIEW_STATUS, SCHEME_ID_INT, ".. p_currentTS .. ", THUMB_STATUS, " .. p_currentTS .. ", FOR_URLEncoder_Url, FOR_ISO_Url, WIDTH, HEIGHT, PARENT_STRUCTURE_NAME, 1, RES_TYPE, BK_TYPE, BK_TYPE_NAME, MATERIAL_TYPE, M3U8_STATUS, M3U8_URL, APP_TYPE_ID, STAGE_ID, SUBJECT_ID, IS_SECONDARY FROM t_resource_info WHERE ID=" .. resInfoId .. ";";
		
		local ssdbUtil = require "multi_check.model.SSDBUtil";
		
		local resInfo = ssdbUtil:multi_hget_hash(
				"resource_" .. resInfoId, 
				"resource_id_int", "resource_title", "resource_type", "resource_type_name", "resource_format", "resource_page",
				"resource_size", "resource_size_int", "create_time", "down_count", "file_id", "thumb_id", "person_id", "identity_id", "person_name", "structure_id", "scheme_id_int", "preview_status", "for_urlencoder_url", "for_iso_url", "width", "height", "res_type", "bk_type_name", "beike_type", "parent_structure_name", "release_status", "m3u8_status", "m3u8_url", "app_type_id", "material_type", "resource_id_char",
				"stage_id", "subject_id", "is_secondary"
			);
		return true, sql, { obj_type=p_objType, info_id=newInfoId, info_map=resInfo };
	end
	
	return false, nil, nil;
end

---------------------------------------------------------------------------
--[[
	局部函数：获取审核通过后需要向对象对应的表插入记录的sql语句和缓存对象
	参数：p_resInfoId 	 原始记录的在T_RESOURCE_INFO表的ID
	参数：p_unitId   	 审核人所在单位的ID
]]

local function _getObjInfoInsertSqlAndCache(p_objIdInt, p_objIdChar, p_unitId, p_objType, strucId)
	if p_objType == 1 then --资源
		return _getResInfoInsertSqlAndCache(p_objIdInt, p_unitId, p_objType);
	elseif p_objType == 2 then -- 试题
		local  quesInfoModel  = require "question.model.QuestionInfo";
		return quesInfoModel: getQuesInfoInsertSqlAndCache(p_objIdChar, strucId, p_unitId, p_objType);
	elseif p_objType == 3 then -- 试卷
		local  paperInfoModel = require "paper.model.PaperInfoModel";
		return paperInfoModel: getPaperInfoInsertSqlAndCache(p_objIdInt, p_unitId, p_objType);
	elseif p_objType == 4 then -- 备课
        return _getResInfoInsertSqlAndCache(p_objIdInt, p_unitId, p_objType);
	elseif p_objType == 5 then -- 微课
		local wkdsModel = require "wkds.model.WkdsModel";
		return wkdsModel: getWkdsInfoInsertSqlAndCache(p_objIdInt, p_unitId, p_objType);
	end

end

---------------------------------------------------------------------------
--[[
	局部函数：向T_BASE_CHECK_FLOW表中审核记录
	参数：p_checkId 	 审核记录的ID
	参数：p_unitId   	 审核人所在单位的ID
	参数：p_unitType 	 单位类型编码
	参数：p_checkStatus  审核状态
	参数：p_checkMsg     审核意见
]]
local function _getInsertCheckFlowSql(p_checkId, p_unitId, p_unitType, p_checkStatus, p_checkMsg, p_personId, p_identityId)
	local p_myTs = require "resty.TS"
	local p_currentTS = p_myTs.getTs();
	
	local ssdblib = require "resty.ssdb"
	local ssdb = ssdblib:new()
	local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
	if not ok then
		ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
		return false;
	end
	local newFlowId = ssdb:incr("t_base_check_flow_pk")[1];
	
	-- 将SSDB连接归还连接池
	ssdb:set_keepalive(0,v_pool_size)
	
	local p_sql = "INSERT INTO T_BASE_CHECK_FLOW (ID, CHECK_ID, UNIT_ID, UNIT_TYPE, CHECK_STATUS, PERSON_ID, IDENTITY_ID, CHECK_TIME, CHECK_MSG, UPDATE_TS)	VALUES ("..newFlowId..", "..p_checkId..", "..p_unitId..", "..p_unitType..", "..p_checkStatus..", "..p_personId..", "..p_identityId..", NOW(), ".. ngx.quote_sql_str(p_checkMsg)..", ".. p_currentTS ..");";
	
	return p_sql;
end

---------------------------------------------------------------------------
--[[
	局部函数：批量向mysql中插入数据
	参数：sqlTable 	 记录sql语句的table
	参数：pSize   	 每批次批量提交的条数
]]
local function _batchInsert2DB(sqlTable, pSize)
	local sql = "START TRANSACTION;";
	if sqlTable~=nil and #sqlTable > 0 then
		
		local DBUtil = require "multi_check.model.DBUtil";
		local db = DBUtil: getDb();
		
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 批量执行sql语句 ===> ");
		local batchFlag = 0;
		for i=1, #sqlTable do
			
			sql = sql .. sqlTable[i];
			batchFlag = batchFlag + 1;
			
			ngx.log(ngx.ERR, "[sj_log]->[multi_check]===>  第", i , "条SQL语句 ===> ", sqlTable[i]);
			if batchFlag == pSize or i==#sqlTable then 
				sql = sql .. "COMMIT;";
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 批量提交的SQL语句 ===> ", sql);
				local res, err, errno, sqlstate = db:query(sql)
				if not res then
					ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> bad result #1: ", err, ": ", errno, ": ", sqlstate, ".");
					return false;
				end

				-- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
				while err == "again" do
					res, err, errno, sqlstate = db:read_result()
					if not res then
						ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> bad result #2: ", err, ": ", errno, ": ", sqlstate, ".")
						return false;
					end
				end
				
				batchFlag = 0;
				sql = "START TRANSACTION;";
			end
		end
		-- 将数据库连接返回连接池
		DBUtil: keepDbAlive(db);
	end
	
	return true;
end

---------------------------------------------------------------------------
--[[
	局部函数：批量向Redis缓存中插入资源缓存
	参数：cacheTable 	 记录资源缓存对象的table
]]
local function _batchInsertRes2Redis(cacheTable)
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	local ssdbUtil = require "multi_check.model.SSDBUtil"
	
	if cacheTable~=nil and #cacheTable > 0 then
		for i=1, #cacheTable do
			local cacheInfo = cacheTable[i];
			local objType   = tonumber(cacheInfo["obj_type"]);
			local infoId 	= cacheInfo["info_id"];
			local infoMap 	= cacheInfo["info_map"];
			if objType == 1 or objType == 4 then -- 1资源，4备课
				local cjson = require "cjson";
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 要保存的缓存信息：<===><===><===> ", cjson.encode(infoMap), " <===><===><===>");
				local result = ssdbUtil: multi_hset("resource_" .. infoId, infoMap);
				--[[ local result, err = ssdbUtil:multi_hset(
					"resource_" .. infoId, 
					"resource_id_int", 		infoMap[1],
					"resource_title", 		infoMap[2],
					"resource_type",        infoMap[3],
					"resource_type_name",   infoMap[4],
					"resource_format",      infoMap[5],
					"resource_page",        infoMap[6],
					"resource_size",        infoMap[7],
					"resource_size_int",    infoMap[8],
					"create_time",          infoMap[9],
					"down_count",           infoMap[10],
					"file_id",              infoMap[11],
					"thumb_id",             infoMap[12],
					"person_id",            infoMap[13],
					"identity_id",          infoMap[14],
					"person_name",          infoMap[15],
					"structure_id",         infoMap[16],
					"scheme_id_int",        infoMap[17],
					"preview_status",       infoMap[18],
					"for_urlencoder_url",   infoMap[19],
					"for_iso_url",          infoMap[20],
					"width",                infoMap[21],
					"height",               infoMap[22],
					"res_type",             infoMap[23],
					"bk_type_name",         infoMap[24],
					"beike_type",           infoMap[25],
					"parent_structure_name",infoMap[26],
					"release_status",       infoMap[27],
					"m3u8_status",          infoMap[28],
					"m3u8_url",             infoMap[29],
					"app_type_id",          infoMap[30],
					"material_type",        infoMap[31],
					"resource_id_char",     infoMap[32],
					"stage_id",		        infoMap[33],
					"subject_id",     		infoMap[34],
					"is_secondary", 		infoMap[35]
				);]]
				
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===>  保存缓存的结果：result:[", cjson.encode(result), "], err: [", err, "]");
			elseif objType==2 then -- 试题
				local quesInfoModel = require "question.model.QuestionInfo";
				quesInfoModel: saveQuestion2Redis(infoId, infoMap, cache);
			elseif objType==3 then -- 试卷
				local paperInfoModel = require "paper.model.PaperInfoModel";
				paperInfoModel: savePaper2Redis(infoId, infoMap, cache);
			elseif objType==4 then -- 备课
			
			elseif objType==5 then -- 微课
				local wkdsModel = require "wkds.model.WkdsModel";
				wkdsModel: saveWkds2Redis(infoId, infoMap, cache);
			end
		end
	end
	
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
end

---------------------------------------------------------------------------
--[[
	局部函数：批量向Redis缓存中插入资源缓存
	参数：cacheTable 	 记录资源缓存对象的table
]]
local function _batchUpdateObjDeleteStatus2Redis(cacheTable)
	local CacheUtil = require "multi_check.model.CacheUtil";
	local cache = CacheUtil: getRedisConn();

	local ssdbUtil = require "multi_check.model.SSDBUtil";
	
	if cacheTable~=nil and #cacheTable > 0 then
		for i=1, #cacheTable do
			local cacheInfo = cacheTable[i];
			local objType   = tonumber(cacheInfo["obj_type"]);
			if objType == 1 or objType == 4 then
				
				local keyName 	= cacheInfo["key"];
	            local fieldName = cacheInfo["field_name"];
				local fieldVal	= cacheInfo["field_value"];
	            ssdbUtil:hset(keyName, fieldName, fieldVal);
			else
				local keyName 	= cacheInfo["key"];
	            local fieldName = cacheInfo["field_name"];
				local fieldVal	= cacheInfo["field_value"];
	            cache:hmset(keyName, fieldName, fieldVal);
			end
		end
	end
	
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
end



local function _getUpdateCheckPathSql(checkId, checkPath)
	local sql = "UPDATE T_BASE_CHECK_INFO SET CHECK_PATH='" .. checkPath .. "' WHERE ID=" .. checkId .. ";";
	return sql;
end

local function _getAnalyseDataInsertSql(stageId, subjectId, unitId, objType, personId, identityId, cacheTable, objIdInt, objIdChar, schemeId, strucId)
	local CacheUtil = require "common.CacheUtil";
	local cache     = CacheUtil: getRedisConn();

	local ssdbUtil  = require "multi_check.model.SSDBUtil";
    
    local cacheMap  = cacheTable.info_map;
    local cjson = require "cjson";
    ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> cacheTable -> [", cjson.encode(cacheTable), "]");
	local size      = 0;
	local resIdInt  = 0;
	if objType == 1 then
		-- size     = cacheMap[8];
		size     = cacheMap["resource_size_int"];
		resIdInt = objIdInt;

	elseif objType == 2 then
		size     = 0;
        resIdInt = 0;
	elseif objType == 3 then
		local resInfoId = cacheMap[24];
		local resCache  = ssdbUtil: multi_hget_hash("resource_" .. resInfoId, "resource_size_int", "resource_id_int");
        CacheUtil: keepConnAlive(cache);
        if not resCache or resCache == nil or resCache == ngx.null or resCache["resource_size_int"] == nil or resCache["resource_size_int"] == ngx.null or resCache["resource_size_int"] == "" then
            size     = 0;
            resIdInt = 0;
        else
            size     = resCache["resource_size_int"];
            resIdInt = resCache["resource_id_int"];
        end
	elseif objType == 4 then
		-- size     = cacheMap[8];
		size     = cacheMap["resource_size_int"];
		resIdInt = objIdInt;
	elseif objType == 5 then
		size     = 0;
	end
	local AnalyseService  = require "management.analyse.services.AnalyseDataService";
	local analyseSqlTable = AnalyseService: insertPlatAnalyseData(stageId, subjectId, unitId, objType, personId, identityId, 1, size, objIdInt, objIdChar, resIdInt, schemeId, strucId);
    return analyseSqlTable;
end

---------------------------------------------------------------------------
--[[
	外部接口：批量审核资源
	参数：unitId 	 	审核单位的ID
	参数：checkArray 	需要审核的资源
	参数：checkMsg 	 	审核的回复信息
]]
local function batchCheck(self, unitId, checkArray, checkMsg, personId, identityId, objType)
	
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> >>>>>>>>>>>>>>>>>>> 审核流程开始！！！ <<<<<<<<<<<<<<<<<<<<<<<< ");
	
	local CheckInfo      = require "multi_check.model.CheckInfo";
	local CheckPerson    = require "multi_check.model.CheckPerson";
	local CheckPath      = require "multi_check.model.CheckPath";
	local CheckConfig    = require "multi_check.model.CheckConfig";
	
	local unitType       = CheckPerson: getUnitType(unitId);
	
	local sql = "";
	local sqlTable = {};
	local cacheTable = {};
	
	-- 循环要审核的记录
	if checkArray~=nil and #checkArray>0 then
		
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 需要审核的记录条数： [", #checkArray, "]条 ！ <=== ");
		
		for i=1, #checkArray do
			local checkId 	  = checkArray[i]["check_id"];
			local checkStatus = tonumber(checkArray[i]["check_status"]);
			ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 开始审核第 [", i, "]条记录：check_id 的值为[" .. checkId .. "], check_status 的值为[" .. checkStatus .. "] ！ <=== ");
			
			-- 1、获取要审核的记录
			local success, checkObj = CheckInfo: getById(checkId);
			if success then				
				-- 2、获取审核记录的审核路径
				local objType       = tonumber(checkObj["OBJ_TYPE"]);
				local objIdInt      = tonumber(checkObj["OBJ_ID_INT"]);
				local objIdChar     = checkObj["OBJ_ID_CHAR"];				
				local forceCheck    = tonumber(checkObj["FORCE_CHECK"]);
				local checkPath     = checkObj["CHECK_PATH"];
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 待审核记录的审核路径为（CHECK_PATH） ===> ", checkPath);
				
				local provinceId    = tonumber(checkObj["PROVINCE_ID"]);
				local cityId        = tonumber(checkObj["CITY_ID"]);
				local districtId    = tonumber(checkObj["DISTRICT_ID"]);
				local pSchoolId     = tonumber(checkObj["P_SCHOOL_ID"]);
				local cSchoolId     = tonumber(checkObj["C_SCHOOL_ID"]);
				local stageId	    = tonumber(checkObj["STAGE_ID"]);
				local subjectId     = tonumber(checkObj["SUBJECT_ID"]);
				local schemeId      = tonumber(checkObj["SCHEME_ID"]);
				local structureId   = tonumber(checkObj["STRUCTURE_ID"]);
				local sharePersonId = tonumber(checkObj["SHARE_PERSON_ID"]);
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 该资源的共享人的ID ===> [", sharePersonId, "]");
				local unitList      = {provinceId, cityId, districtId, pSchoolId, cSchoolId};
				
				local pathBean      = CheckPath: new(unitId, checkPath);
				local currStatus    = pathBean: getCheckStatusByLevel(unitType);
				local destUnitLevel, currUnitLevel, tempStatus = pathBean: getDestUnit();
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 当前审核单位的审核状态： ===> ", currStatus, ", unitType: ", unitType, ", pathBean._status_table[" .. unitType .. "] : ",  pathBean._status_table[unitType]);
								
				if currStatus == "10" then
					-- 根据审核状态修改审核路径中当前机构对应的审核状态
					pathBean: setCheckStatus(unitType, checkStatus);
					checkPath = pathBean: getCheckPath();
					ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 当前单位审核后的审核路径为（CHECK_PATH） ===> ", checkPath);
					
					-- 原状态为10（待审核），那么修改后一定不会是待审核，减少待审核条数的统计数据
					if destUnitLevel ~= currUnitLevel then
						local paramTable = AnalyseService: getParamFromCheckInfo(checkObj);
				        paramTable["dest_org_id"] = checkObj[fieldTab[destUnitLevel]];
				        paramTable["unit_id"]     = unitId;
				        paramTable["unit_type"]   = unitType;
						local updateWaitCheckSql  = AnalyseService: decreaseWaitCheckCount(paramTable);
	        			table.insert(sqlTable, updateWaitCheckSql);
					end

					if checkStatus == 12 then -- 审核状态为[审核未通过]	
											
						sql = _getUpdateCheckPathSql(checkId, checkPath);
						table.insert(sqlTable, sql);
						
						sql = _getInsertCheckFlowSql(checkId, unitId, unitType, "12", checkMsg, personId, identityId);
						table.insert(sqlTable, sql);
							
					elseif checkStatus == 11 then -- 审核状态为[审核通过]	
							
						-- 向T_RESOURCE_INFO表中插入对应单位的资源记录
						local insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, unitId, objType, structureId);
						if insertFlag then 
							table.insert(sqlTable	, insertSql);
							table.insert(cacheTable	, cacheInfo);
							
							local cjson = require "cjson";
							ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 资源缓存的值 ===> ", cjson.encode(cacheInfo));
							local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, unitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId);
	                        table.insert(sqlTable, analyseSqlTable[1]);
	                        table.insert(sqlTable, analyseSqlTable[2]);
	                        
							-- 向T_BASE_CHECK_FLOW（审核流程表）表中插入审核记录
							sql = _getInsertCheckFlowSql(checkId, unitId, unitType, "11", checkMsg, personId, identityId);
							table.insert(sqlTable, sql);
						end
						
						-- 如果当前审核记录的审核模式为单级审核，审核通过后需要向所有下级单位插入资源对象
						local nextLevelStatus = pathBean: getCheckStatusByLevel(unitType + 1);
						
						--ngx.log(ngx.ERR, "===> 下级单位的状态：[", nextLevelStatus, "], 类型：[", type(nextLevelStatus), "] <===");
						-- 如果下级单位的审核状态为00或01，则表示该审核记录为单级审核
						if nextLevelStatus == "00" or nextLevelStatus == "01" then
							--ngx.log(ngx.ERR, "===> 开始循环下级单位 <=== ");
							-- 循环所有下级单位，插入资源数据
							for nextLevel = unitType + 1, 5 do
								local nextLevelStatus = pathBean: getCheckStatusByLevel(nextLevel);
								--ngx.log(ngx.ERR, "===> 下级单位的级别：[", nextLevel, "], 状态：[", nextLevelStatus, "] <===");
								if nextLevelStatus == "00" then --01表示为该资源已经被截留，不需要再插入数据
									local nextUnitId 	  = unitList[nextLevel];
									-- 向T_RESOURCE_INFO表中插入对应单位的资源记录
									local insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, nextUnitId, objType, structureId);
									if insertFlag then 
										table.insert(sqlTable, insertSql);
										table.insert(cacheTable, cacheInfo);
										
										local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, nextUnitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId)
				                        table.insert(sqlTable, analyseSqlTable[1]);
				                        table.insert(sqlTable, analyseSqlTable[2]);
									end
			                        
								end -- nextLevelStatus == "00" then
								pathBean: setCheckStatus(nextLevel, "11");
							end -- for nextLevel = unitType + 1, 5 do
							
							-- ngx.log(ngx.ERR, "===> 循环下级单位结束 <=== ");
						end -- if nextLevelStatus == "00" or nextLevelStatus == "01" then
						
						-- 5、循环当前审核机构的上级机构，判断审核状态是否为10（待审）
						for level=unitType-1, 1, -1 do
							local upLevelStatus = pathBean: getCheckStatusByLevel(level);
							local tempUnitId = unitList[level];
							ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 循环上级结构，单位级别:[ ", level, "], 上级单位的ID：[", tempUnitId, "]");
							
							if upLevelStatus == "10" then -- 审核状态为[待审核]
								ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 强制下级审核:[", forceCheck, "], 类型：[", type(forceCheck), "]");
								if forceCheck == 0 then -- [不强制要求下级审核]
									-- 判断上级单位是否为***自动通过***
									local autoPass, checkWay = CheckConfig:getConfig(tempUnitId);
									ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 循环上级结构，审核是否自动通过:[", autoPass, "], 审核机制：[", checkWay, "]");
									if autoPass == 1 then -- 如果为自动通过
										pathBean: setCheckStatus(level, "11");
										
										-- 向T_RESOURCE_INFO表中插入对应单位的资源记录
										insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, tempUnitId, objType, structureId);
										if insertFlag then 
											table.insert(sqlTable, insertSql);
											table.insert(cacheTable, cacheInfo);
											
											local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, tempUnitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId)
				                        	table.insert(sqlTable, analyseSqlTable[1]);
				                        	table.insert(sqlTable, analyseSqlTable[2]);
											
											-- 向T_BASE_CHECK_FLOW表中插入审核记录									
											sql = _getInsertCheckFlowSql(checkId, tempUnitId, level, "11", "自动通过审核。", 0, 0);
											table.insert(sqlTable, sql);
										end

									else
										break;
									end
								end
							else
								break;
							end
						end
					end -- if checkStatus == 12 then
					
					checkPath = pathBean: getCheckPath();
					ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 审核结束时的审核路径: ['", checkPath, "'] <===");
					
					-- 审核结束时，判断审核路径，对数据进行管理
					local destUnitLevel, currUnitLevel, tempStatus = pathBean: getDestUnit();
					ngx.log(ngx.ERR, "\n[sj_log]->[multi_check]===> destUnitLevel: ['", destUnitLevel, "'] , currUnitLevel: ['", currUnitLevel, "'], tempStatus: ['", tempStatus, "']<===\n");
					if (tempStatus == "10" or tempStatus == "13") and (destUnitLevel ~= currUnitLevel) then
				        local paramTable = AnalyseService: getParamFromCheckInfo(checkObj);
			        	paramTable["dest_org_id"] = checkObj[fieldTab[destUnitLevel]];
			        	paramTable["unit_id"]     = checkObj[fieldTab[currUnitLevel]];
			        	paramTable["unit_type"]   = currUnitLevel;
			        	ngx.log(ngx.ERR, "\n [sj_log] -> [multi_check] -> paramTable: [", encodeJson(paramTable), "]\n");
				        local updateWaitCheckSql  = AnalyseService: increaseWaitCheckCount(paramTable);
				        table.insert(sqlTable, updateWaitCheckSql);
				    end
					
					-- 更新T_BASE_CHECK_INFO（审核信息表）表中审核记录的CHECK_PATH字段的值
					sql = _getUpdateCheckPathSql(checkId, checkPath);
					table.insert(sqlTable, sql);
					
				end	-- if currStatus == "10" then	
			end -- if success then	
		end --  for i=1, #checkArray do
	end -- if checkArray~=nil and #checkArray>0 then
	
	local result = _batchInsert2DB(sqlTable, 50);
	_batchInsertRes2Redis(cacheTable);
	
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> >>>>>>>>>>>>>>>>>>> 审核流程结束！！！ <<<<<<<<<<<<<<<<<<<<<<<< ");
	if not result then
		return false, "资源审核出错";
	end
	return true, "资源审核完成。"

end

_MultiCheck.batchCheck = batchCheck;

---------------------------------------------------------------------------------------
--[[
	外部接口：修改审核结果
	参数：unitId 	 	单位ID
	参数：checkId 		审核记录的ID
	参数：checkStatus 	修改后的审核状态
	参数：checkMsg		审核信息
]]
local function modifyCheckStatus(self, unitId, checkId, checkStatus, checkMsg, personId, identityId)
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> >>>>>>>>>>>>>>>>>>> 修改审核结果 -> [START] <<<<<<<<<<<<<<<<<<<<<<<< ");
	local CheckInfo   = require "multi_check.model.CheckInfo";
	local CheckPerson = require "multi_check.model.CheckPerson";
	local CheckPath   = require "multi_check.model.CheckPath";
	local CheckConfig = require "multi_check.model.CheckConfig";
	local AnalyseService  = require "management.analyse.services.AnalyseDataService";
	
	local unitType = CheckPerson: getUnitType(unitId);
	local autoPass, currCheckWay = CheckConfig:getConfig(unitId);
	-- 1、获取要审核的记录
	local success, checkObj = CheckInfo: getById(checkId);
	if success then				
		-- 2、获取审核记录的审核路径
		local objType 	 = tonumber(checkObj["OBJ_TYPE"]);
		local objIdInt   = tonumber(checkObj["OBJ_ID_INT"]);
		local objIdChar  = checkObj["OBJ_ID_CHAR"];
		local checkPath  = checkObj["CHECK_PATH"];
		local checkWay   = tonumber(checkObj["CHECK_WAY"]);
		local forceCheck = tonumber(checkObj["FORCE_CHECK"]);
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 待审核记录的审核路径为（CHECK_PATH） ===> ", checkPath);
		
		local provinceId    = tonumber(checkObj["PROVINCE_ID"]);
		local cityId        = tonumber(checkObj["CITY_ID"]);
		local districtId    = tonumber(checkObj["DISTRICT_ID"]);
		local pSchoolId     = tonumber(checkObj["P_SCHOOL_ID"]);
		local cSchoolId     = tonumber(checkObj["C_SCHOOL_ID"]);
		local stageId       = tonumber(checkObj["STAGE_ID"]);
		local subjectId     = tonumber(checkObj["SUBJECT_ID"]);
		local schemeId      = tonumber(checkObj["SCHEME_ID"]);
		local structureId   = tonumber(checkObj["STRUCTURE_ID"]);
		local sharePersonId = tonumber(checkObj["SHARE_PERSON_ID"]);
		local unitList      = {provinceId, cityId, districtId, pSchoolId, cSchoolId};

		
		local pathBean   = CheckPath: new(unitId, checkPath);									
		local currStatus = pathBean: getCurrentLevelStatus();
		local canModify	  = pathBean: canModifyStatus();
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 当前审核单位：当前审核状态：[", currStatus, "] ===> 修改后的审核状态：[", checkStatus, "] ===> 审核机制：[", checkWay, "] ===> 是否允许修改：[", canModify, "] <===");
		
		local sqlTable 	 	= {};		
		local cacheTable 	= {};
		local delCacheTable = {};
		local sql 		 	= "";
		
		if canModify then -- 判断该记录是否允许修改审核结果
		
			if checkStatus == currStatus then -- 如果状态值没变，则只向流程表中插入一条审核流程记录
			
				-- 向T_BASE_CHECK_FLOW表中插入审核记录									
				sql = _getInsertCheckFlowSql(checkId, unitId, unitType, checkStatus, checkMsg, personId, identityId);
				table.insert(sqlTable, sql);
				
			else
			
				pathBean: setCheckStatus(unitType, checkStatus);
				if checkStatus == "12" then -- 将状态修改为[审核不通过]
					local boolFlag, sql, cacheInfo = CheckInfo: getDeleteObjSql(objType, objIdInt, objIdChar, structureId, unitId);
					if boolFlag then 
						table.insert(sqlTable		, sql);
						table.insert(delCacheTable	, cacheInfo);

						-- 向T_BASE_CHECK_FLOW表中插入审核记录									
						sql = _getInsertCheckFlowSql(checkId, unitId, unitType, checkStatus, checkMsg, personId, identityId);
						table.insert(sqlTable, sql);

						-- 删除info表记录的同时，删除统计数据
						local analyseSqlTable = AnalyseService: getDelPlatAnalyseSql(objIdInt, objIdChar, objType, structureId, sharePersonId, 5, {unitId});
					    if analyseSqlTable ~= nil and #analyseSqlTable ~= 0 then
					        for index = 1, #analyseSqlTable do
					            local delAnalyseSql = analyseSqlTable[index];
					            table.insert(sqlTable, delAnalyseSql);
					        end
					    end

					    -- 将资源和备课修改为不通过时，需要维护对应的多级门户的统计数据
					    -- if objType == 1 or objType == 4 then 					    	
					    -- 	local djmhTjwh = require "new_djmh.model.whdjmhtj";
					    -- 	djmhTjwh: whdjmhtj(unitId, objIdInt);
					    -- end

					    -- 删除推荐的记录
					    checkObj["GROUP_IDS"]  = { unitId };
					    local RecommendModel = require "multi_check.model.Recommend";
					    RecommendModel: delRecommendData(checkObj);

					end				
				
				elseif checkStatus == "11" then -- 将状态修改为[审核通过]
					
					local insertFlag, insertSql, cacheInfo;
					if checkWay == 1 then -- 如果为[单级审核]
						
						-- 向T_BASE_CHECK_FLOW表中插入审核记录									
						sql = _getInsertCheckFlowSql(checkId, unitId, unitType, "11", checkMsg, personId, identityId);
						table.insert(sqlTable, sql);
						
						for level=unitType, 5 do -- 循环下级单位，向每级单位插入资源记录
							local downUnitId = unitList[level];
							pathBean: setCheckStatus(level, "11");
							insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, downUnitId, objType, structureId);
							if insertFlag then 
								table.insert(sqlTable	, insertSql);
								table.insert(cacheTable	, cacheInfo);

								-- 插入统计数据
								local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, downUnitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId);
	                        	table.insert(sqlTable, analyseSqlTable[1]);
	                        	table.insert(sqlTable, analyseSqlTable[2]);
							end
						end
						
					else -- 如果为多级审核
						
						pathBean: setCheckStatus(unitType, "11");
						-- 向T_RESOURCE_INFO表中插入对应单位的资源记录
						insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, unitId, objType, structureId);
						if insertFlag then 
							table.insert(sqlTable	, insertSql);
							table.insert(cacheTable	, cacheInfo);

							-- 向T_BASE_CHECK_FLOW表中插入审核记录									
							sql = _getInsertCheckFlowSql(checkId, unitId, unitType, "11", checkMsg, personId, identityId);
							table.insert(sqlTable, sql);

							-- 插入统计数据
							local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, unitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId)
	                        table.insert(sqlTable, analyseSqlTable[1]);
	                        table.insert(sqlTable, analyseSqlTable[2]);
						end
						
						-- 5、循环当前审核机构的上级机构，判断审核状态是否为10（待审）
						for level=unitType-1, 1, -1 do
							local upLevelStatus = pathBean: getCheckStatusByLevel(level);
							local upUnitId 		= unitList[level];
							ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 循环上级结构，单位级别:[", level, "], 上级单位的ID：[", tempUnitId, "]");
							
							if upLevelStatus == "10" then -- 状态为[待审核]
								if forceCheck == 0 then  -- [不强制下级单位审核]
									-- 判断上级单位是否为***自动通过***
									local upAutoPass, upCheckWay = CheckConfig:getConfig(upUnitId);
									if upAutoPass == 1 then -- 如果上级单位为自动通过
										pathBean: setCheckStatus(level, "11");
										-- 向T_RESOURCE_INFO表中插入对应单位的资源记录
										insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, upUnitId, objType, structureId);
										if insertFlag then 
											table.insert(sqlTable, insertSql);
											table.insert(cacheTable, cacheInfo);
											
											-- 插入统计数据
											local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, upUnitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId)
	                        				table.insert(sqlTable, analyseSqlTable[1]);
	                        				table.insert(sqlTable, analyseSqlTable[2]);
											
											-- 向T_BASE_CHECK_FLOW表中插入审核记录			
											sql = _getInsertCheckFlowSql(checkId, upUnitId, level, "11", "自动通过审核。", 0, 0);
											table.insert(sqlTable, sql);
										end
									else -- 如果上级单位不是自动通过，则跳出循环
										break;
									end
								end
							else
								break;
							end
						end -- for level=unitType-1, 1, -1 do
					end -- if checkWay == 1 then
				end -- if checkStatus == "12" then 
				local checkPath  = pathBean: getCheckPath();
				sql = CheckInfo: getUpdateCheckPathSql(checkId, checkPath);
				table.insert(sqlTable, sql);
			end -- if checkStatus == currStatus then
			
			local result = _batchInsert2DB(sqlTable, 50);
			_batchInsertRes2Redis(cacheTable);
			_batchUpdateObjDeleteStatus2Redis(delCacheTable);
			
			if not result then 
				return false, "修改审核结果失败。";
			end
			
		else
			return false, "该记录已经被上级审核，无法修改审核结果。";
		end -- if canModify then
	else
		return false, "获取审核记录失败。";
	end 
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> >>>>>>>>>>>>>>>>>>> 修改审核结果 -> [END] <<<<<<<<<<<<<<<<<<<<<<<< ");
	return true, "修改审核结果成功。";
end

_MultiCheck.modifyCheckStatus = modifyCheckStatus;

---------------------------------------------------------------------------------------
--[[
	描述：代替下级进行审核
	参数：unitId 	 	单位ID
	参数：checkId 		审核记录的ID
	参数：checkStatus 	修改后的审核状态
	参数：checkMsg		审核信息
]]
local function supersedeCheck(self, unitId, checkArray, checkMsg, personId, identityId)
	local CheckInfo   = require "multi_check.model.CheckInfo";
	local CheckPerson = require "multi_check.model.CheckPerson";
	local CheckPath   = require "multi_check.model.CheckPath";
	local CheckConfig = require "multi_check.model.CheckConfig";
	local AnalyseService  = require "management.analyse.services.AnalyseDataService";
	
	local sqlTable 	 	= {};		
	local cacheTable 	= {};

	local unitNames = {"省", "市", "区", "校", "分校"};
	local unitType = CheckPerson: getUnitType(unitId);
	checkMsg   = checkMsg .. "【" .. unitNames[unitType] .. "级单位代审】";

	-- 循环要审核的记录
	if checkArray~=nil and #checkArray>0 then
		
		ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 需要审核的记录条数： [", #checkArray, "]条 ！ <=== ");
		
		for i=1, #checkArray do
			local checkId 	  = checkArray[i]["check_id"];
			local checkStatus = checkArray[i]["check_status"];

			
			local autoPass, currCheckWay = CheckConfig:getConfig(unitId);
			-- 1、获取要审核的记录
			local success, checkObj = CheckInfo: getById(checkId);
			if success then				
				-- 2、获取审核记录的审核路径
				local objType 	 = tonumber(checkObj["OBJ_TYPE"]);
				local objIdInt   = tonumber(checkObj["OBJ_ID_INT"]);
				local objIdChar  = checkObj["OBJ_ID_CHAR"];
				local checkPath  = checkObj["CHECK_PATH"];
				local checkWay   = tonumber(checkObj["CHECK_WAY"]);
				local forceCheck = tonumber(checkObj["FORCE_CHECK"]);
				ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 待审核记录的审核路径为（CHECK_PATH） ===> ", checkPath);
				
				local provinceId    = tonumber(checkObj["PROVINCE_ID"]);
				local cityId        = tonumber(checkObj["CITY_ID"]);
				local districtId    = tonumber(checkObj["DISTRICT_ID"]);
				local pSchoolId     = tonumber(checkObj["P_SCHOOL_ID"]);
				local cSchoolId     = tonumber(checkObj["C_SCHOOL_ID"]);
				local stageId       = tonumber(checkObj["STAGE_ID"]);
				local subjectId     = tonumber(checkObj["SUBJECT_ID"]);
				local schemeId      = tonumber(checkObj["SCHEME_ID"]);
				local structureId   = tonumber(checkObj["STRUCTURE_ID"]);
				local sharePersonId = tonumber(checkObj["SHARE_PERSON_ID"]);
				local unitList      = {provinceId, cityId, districtId, pSchoolId, cSchoolId};

				
				local pathBean   = CheckPath: new(unitId, checkPath);									
				local currStatus = pathBean: getCurrentLevelStatus();
				local canModify	 = pathBean: canModifyStatus();
				local destLevel, currentLevel, tempStatus = pathBean: getDestUnit();

				ngx.log(ngx.ERR, "\n[sj_log]->[multi_check]===> \n当前审核状态：[", currStatus, "] \n===> 审核后的审核状态：[", checkStatus, "] \n===> 审核机制：[", checkWay, "] ===> 是否允许修改：[", canModify, "]  \n===> 共享目标：[", unitNames[destLevel], "] \n===> 当前审核单位：[", unitNames[currentLevel], "] <===\n");

				-- 原状态为10（待审核），那么修改后一定不会是待审核，减少待审核条数的统计数据
				if destLevel ~= currUnitLevel then
					local paramTable = AnalyseService: getParamFromCheckInfo(checkObj);
			        paramTable["dest_org_id"] = checkObj[fieldTab[destLevel]];
			        paramTable["unit_id"]     = checkObj[fieldTab[currentLevel]];
			        paramTable["unit_type"]   = currentLevel;
					local updateWaitCheckSql  = AnalyseService: decreaseWaitCheckCount(paramTable);
	    			table.insert(sqlTable, updateWaitCheckSql);
	    		end

				if checkStatus == "11" then
					for index = currentLevel, unitType, -1 do
						local tempUnitId = unitList[index];

						pathBean: setCheckStatus(index, "11");

						-- 向T_RESOURCE_INFO表中插入对应单位的资源记录
						local insertFlag, insertSql, cacheInfo = _getObjInfoInsertSqlAndCache(objIdInt, objIdChar, tempUnitId, objType, structureId);
						if insertFlag then 
							table.insert(sqlTable	, insertSql);
							table.insert(cacheTable	, cacheInfo);
							
							local cjson = require "cjson";
							ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> 资源缓存的值 ===> ", cjson.encode(cacheInfo));
							local analyseSqlTable = _getAnalyseDataInsertSql(stageId, subjectId, tempUnitId, objType, sharePersonId, 5, cacheInfo, objIdInt, objIdChar, schemeId, structureId);
	                        table.insert(sqlTable, analyseSqlTable[1]);
	                        table.insert(sqlTable, analyseSqlTable[2]);
	                        
							-- 向T_BASE_CHECK_FLOW（审核流程表）表中插入审核记录
							sql = _getInsertCheckFlowSql(checkId, tempUnitId, unitType, "11", checkMsg, personId, identityId);
							table.insert(sqlTable, sql);
						end
					end
				else
					pathBean: setCheckStatus(currentLevel, "12");
					sql = _getInsertCheckFlowSql(checkId, unitList[currentLevel], currentLevel, "12", checkMsg, personId, identityId);
						table.insert(sqlTable, sql);
				end
				local checkPath  = pathBean: getCheckPath();
				sql = CheckInfo: getUpdateCheckPathSql(checkId, checkPath);
				table.insert(sqlTable, sql);

				-- 审核结束时，判断审核路径，对数据进行管理
				local destUnitLevel, currUnitLevel, tempStatus = pathBean: getDestUnit();
				ngx.log(ngx.ERR, "\n[sj_log]->[multi_check]===> destUnitLevel: ['", destUnitLevel, "'] , currUnitLevel: ['", currUnitLevel, "'], tempStatus: ['", tempStatus, "']<===\n");
				if (tempStatus == "10" or tempStatus == "13") and (destUnitLevel ~= currUnitLevel) then
			        local paramTable = AnalyseService: getParamFromCheckInfo(checkObj);
		        	paramTable["dest_org_id"] = checkObj[fieldTab[destUnitLevel]];
		        	paramTable["unit_id"]     = checkObj[fieldTab[currUnitLevel]];
		        	paramTable["unit_type"]   = currUnitLevel;
		        	ngx.log(ngx.ERR, "\n [sj_log] -> [multi_check] -> paramTable: [", encodeJson(paramTable), "]\n");
			        local updateWaitCheckSql  = AnalyseService: increaseWaitCheckCount(paramTable);
			        table.insert(sqlTable, updateWaitCheckSql);
			    end
			end
		end
	end

	local result = _batchInsert2DB(sqlTable, 50);
	_batchInsertRes2Redis(cacheTable);
	
	ngx.log(ngx.ERR, "[sj_log]->[multi_check]===> >>>>>>>>>>>>>>>>>>> 代替下级审核流程结束！！！ <<<<<<<<<<<<<<<<<<<<<<<< ");
	if not result then
		return false, "资源审核出错";
	end
	return true, "资源审核完成。"

end

_MultiCheck.supersedeCheck = supersedeCheck;
---------------------------------------------------------------------------------------
return _MultiCheck;