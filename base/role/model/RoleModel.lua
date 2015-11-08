--[[
	局部函数：角色基础信息接口

]]
local _RoleModel = {};

--[[
    描述： 根据角色编码查询角色详情
    作者： 胡悦 2015-08-18
    参数：    roleCode 角色编码
    返回值：返回第一条数据
]]
local function getRoleByRoleCode(self,roleCode)

	local query_role_sql = "select ROLE_ID,ROLE_NAME,ROLE_CODE,BUSINESS_SYSTEM_SOURCE from t_sys_role where role_code = '"..roleCode.."' and B_USE=1";	
	ngx.log(ngx.ERR, "[hy_log]->[RoleModel]-> 查询角色而编码查询角色详情的Sql语句 ===> [[["..query_role_sql.."]]]");
	local DBUtil      = require "common.DBUtil";
    local queryRoleResult = DBUtil: querySingleSql(query_role_sql);
    if not queryRoleResult or queryRoleResult[1]==nil then
        return false;
    end
	
	--local resultTable = {};
   -- for index=1, #queryRoleResult do
    local record = queryRoleResult[1];
     --   local resultObj = {};
      --  resultObj["role_id"]        = record["ROLE_ID"];
     --   resultObj["role_name"]      = record["ROLE_NAME"];
     --   resultObj["role_code"]      = record["ROLE_CODE"];
     --   resultObj["business_system_source"]    = record["BUSINESS_SYSTEM_SOURCE"];
    	
    --    table.insert(resultTable, resultObj);
 --   end
    return record;
end

_RoleModel.getRoleByRoleCode = getRoleByRoleCode;
---------------------------------------------------------------------------
local function getRolesByRoleIds(self,roleId)

	local query_role_sql = "select ROLE_ID,ROLE_NAME,ROLE_CODE,BUSINESS_SYSTEM_SOURCE from t_sys_role where role_id in ( "..roleId.." ) and B_USE=1";	
	ngx.log(ngx.ERR, "[hy_log]->[RoleModel]-> 查询角色而编码查询角色详情的Sql语句 ===> [[["..query_role_sql.."]]]");
	local DBUtil      = require "common.DBUtil";
    local queryRoleResult = DBUtil: querySingleSql(query_role_sql);
    if not queryRoleResult or queryRoleResult[1]==nil then
        return false;
    end
	
    return queryRoleResult;
end

_RoleModel.getRolesByRoleIds = getRolesByRoleIds;
---------------------------------------------------------------------------


--[[
    描述： 根据角色ID查询人员信息
    作者： 胡悦 2015-08-18
    参数：    roleId 角色ID
    返回值：存储结果的table
]]

local function getUsersByRoleId(self,role_id,pageSize,pageNumber)
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize

	local DBUtil      = require "common.DBUtil";
	local query_condition = " where 1=1 ";
	query_condition= query_condition.." and t1.role_id ="..role_id;
	local query_identity_sql = "select identity_id from t_sys_role where role_id="..role_id;
	ngx.log(ngx.ERR,"hy_log-->根据角色查询身份"..query_identity_sql);
	local query_identity_res=DBUtil: querySingleSql(query_identity_sql);
	if  query_identity_res and query_identity_res[1] then
		identity_id=tonumber(query_identity_res[1]["identity_id"]);
	end


	local query_person_sql,query_count_sql;
	if identity_id==6 then
		--查询学生表
		query_person_sql="select distinct t2.student_id as person_id,t2.stu_num as person_num,t2.student_name as person_name,t4.org_id,t4.org_name as person_name from T_SYS_PERSON_ROLE t1  join t_base_student t2 on t1.person_id=t2.student_id join t_base_class t3 on t2.class_id =t3.class_id join t_base_organization t4 on t3.org_id=t4.org_id "..query_condition.." order by person_name LIMIT "..offset..","..limit; 	
	else
		query_person_sql="select distinct t2.person_id,t2.person_name,t2.person_num,t2.org_id,t3.org_name from T_SYS_PERSON_ROLE t1  join t_base_person t2 on t1.person_id=t2.person_id left join t_base_organization t3 on t2.org_id=t3.org_id  "..query_condition.." order by  person_name LIMIT "..offset..","..limit; 	

	end
	ngx.log(ngx.ERR,"hy_log-->根据角色查询人的信息"..query_person_sql);

	local query_person_res=DBUtil: querySingleSql(query_person_sql);
	local resultTable = {};
	for i=1,#query_person_res do
		local person_res={};
		local person_id = query_person_res[i]["person_id"];
		person_res["PERSON_ID"]=person_id;
		person_res["PERSON_NAME"]=query_person_res[i]["person_name"];
		person_res["ORG_ID"]=query_person_res[i]["org_id"];
		person_res["ORG_NAME"]=query_person_res[i]["org_name"];
		person_res["PERSON_NUM"]=query_person_res[i]["person_num"];
		table.insert(resultTable, person_res);
	end
	return resultTable;
end

_RoleModel.getUsersByRoleId = getUsersByRoleId;

---------------------------------------------------------------------------

--[[
    描述： 根据角色ID查询人员信息
    作者： 胡悦 2015-08-18
    参数：    roleId 角色ID
    返回值：存储结果的table
]]

local function getUsersCountByRoleId(self,role_id)

	local DBUtil      = require "common.DBUtil";
	local query_condition = " where 1=1 ";
	query_condition= query_condition.." and t1.role_id ="..role_id;
	local query_identity_sql = "select identity_id from t_sys_role where role_id="..role_id;
	ngx.log(ngx.ERR,"hy_log-->根据角色查询身份"..query_identity_sql);
	local query_identity_res=DBUtil: querySingleSql(query_identity_sql);
	if  query_identity_res and query_identity_res[1] then
		identity_id=tonumber(query_identity_res[1]["identity_id"]);
	end


	local query_count_sql;
	if identity_id==6 then
		--查询学生表
		query_count_sql="select count(distinct t2.student_id) as count from T_SYS_PERSON_ROLE t1  join t_base_student t2 on t1.person_id=t2.student_id join t_base_class t3 on t2.class_id =t3.class_id join t_base_organization t4 on t3.org_id=t4.org_id "..query_condition.." order by person_name";	
	else
		query_count_sql="select count(distinct t2.person_id) as count from T_SYS_PERSON_ROLE t1  join t_base_person t2 on t1.person_id=t2.person_id left join t_base_organization t3 on t2.org_id=t3.org_id  "..query_condition.." order by  person_name ";	

	end
	ngx.log(ngx.ERR,"hy_log-->根据角色查询人的信息"..query_count_sql);

	local query_person_res=DBUtil: querySingleSql(query_count_sql);
	
	local totalRow = query_person_res[1]["count"];

	return totalRow;
end

_RoleModel.getUsersCountByRoleId = getUsersCountByRoleId;
---------------------------------------------------------------------------
--[[
    描述： 根据菜单ID和当前登录人角色ID查询当前的角色ID
    作者： 胡悦 2015-08-18
    参数： menu_id 菜单ID，role_ids_str 当前登录人的角色ID
    返回值：存储结果的table
]]
local function getCurrentRolesByMenuIdAndRoleIds(selef,menu_id,role_ids_str)
	local DBUtil = require "common.DBUtil";
	local query_role_sql="select role_id  from t_sys_role_menu where menu_id = "..menu_id.." and role_id in ("..role_ids_str..")";
	ngx.log(ngx.ERR,"hy_log-->查询角色"..query_role_sql);
	local query_role_res=DBUtil: querySingleSql(query_role_sql);
	return query_role_res;
end
_RoleModel.getCurrentRolesByMenuIdAndRoleIds = getCurrentRolesByMenuIdAndRoleIds;
---------------------------------------------------------------------------
--[[
    描述： 根据当前登录人ID和角色ID查询角色管理的组织
    作者： 胡悦 2015-08-18
    参数： person_id 当前登录用户ID,current_role_ids_str 当前角色ID,identity_id 身份ID
    返回值：存储结果的table
]]
local function getRoleOrgsByRoleIdsAndPersonId(self,person_id,current_role_ids_str,identity_id)
	local DBUtil = require "common.DBUtil";
	local query_org_sql = "select distinct r.org_id,o.org_name,o.parent_id,o.org_code,o.org_type,o.area_id  from t_sys_person_role r  join t_base_organization o on  r.org_id=o.org_id where role_id in ("..current_role_ids_str..") and identity_id ="..identity_id.." and person_id ="..person_id;
	ngx.log(ngx.ERR,"hy_log-->查询组织IDSQL"..query_org_sql);
	local query_org_res=DBUtil: querySingleSql(query_org_sql);
	local resultTable = {};
	for i=1,#query_org_res do

		local org_res={};
		org_res["ORG_ID"]=query_org_res[i]["org_id"];
		org_res["ORG_NAME"]=query_org_res[i]["org_name"];
		org_res["PARENT_ID"]=query_org_res[i]["parent_id"];
		org_res["ORG_CODE"]=query_org_res[i]["org_code"];
		org_res["ORG_TYPE"]=query_org_res[i]["org_type"];
		local area_id = query_org_res[i]["area_id"];
		local org_type = query_org_res[i]["org_type"];
		if tonumber(org_type)==1 then
			--org_res["ORG_LEVEL"]=1;
			--id > 100000 && id < 200000
			if tonumber(area_id)>100000 and tonumber(area_id)<200000 then 
				org_res["ORG_LEVEL"]=1;
			elseif tonumber(area_id)>200000 and tonumber(area_id)<300000 then
				org_res["ORG_LEVEL"]=2;
			else 
				org_res["ORG_LEVEL"]=3;
			end
			
		elseif tonumber(org_type)==2 then
			org_res["ORG_LEVEL"]=4;
		
		elseif tonumber(org_type)==3 then
			org_res["ORG_LEVEL"]=5;
		
		end
		
		table.insert(resultTable, org_res);
	
	--[[
	local org_type = query_org_res[i]["org_type"];
		local org_id = query_org_res[i]["org_id"];
		--如果是教育局只查询教育局下的部门，如果是其他则递归向下一直查询
		local sql;
		if tonumber(org_type)==1 then 
			
		else
		
		end
		]]		
	end

	return resultTable;
end
_RoleModel.getRoleOrgsByRoleIdsAndPersonId = getRoleOrgsByRoleIdsAndPersonId;
---------------------------------------------------------------------------
return _RoleModel;