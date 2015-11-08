--[[
	胡悦
	角色信息基础接口
]]

local _RoleService = {};

--[[
    描述： 根据角色编码查询角色用户
    作者： 胡悦 2015-08-18
    参数：    roleCode 角色编码
    返回值：存储结果的table
]]
local function getUsersByRoleCode(self,roleCode,pageSize,pageNumber)
	local roleModel = require "base.role.model.RoleModel";
	local role=roleModel:getRoleByRoleCode(roleCode);
	if not role then
		return { success=false, info="没有该角色编码" };
	end
	local roleId = role["ROLE_ID"];
	local peopleTable = roleModel:getUsersByRoleId(roleId,pageSize,pageNumber);
	local totalRow = roleModel:getUsersCountByRoleId(roleId);
	
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	
	--result["totalRow"] = tonumber(totalRow)
	--result["totalPage"] = tonumber(totalPage)
	--result["pageNumber"] = tonumber(pageNumber)
	--result["pageSize"] = tonumber(pageSize)
	if not peopleTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=peopleTable,totalRow= tonumber(totalRow),totalPage=tonumber(totalPage),pageNumber=tonumber(pageNumber),pageSize=tonumber(pageSize)};

end

_RoleService.getUsersByRoleCode = getUsersByRoleCode;
---------------------------------------------------------------------------
--[[
    描述： 根据菜单ID和当前登录人角色ID查询当前的角色ID
    作者： 胡悦 2015-08-18
    参数： menu_id 菜单ID，role_ids_str 当前登录人的角色ID
    返回值：存储结果的table
]]
local function getCurrentRolesByMenuIdAndRoleIds(selef,menu_id,role_ids_str)
	local roleModel = require "base.role.model.RoleModel";
	local roleIds = roleModel:getCurrentRolesByMenuIdAndRoleIds(menu_id,role_ids_str);
	
	return roleIds;
end
_RoleService.getCurrentRolesByMenuIdAndRoleIds = getCurrentRolesByMenuIdAndRoleIds;
---------------------------------------------------------------------------
--[[
    描述： 根据当前登录人ID和角色ID查询角色管理的组织
    作者： 胡悦 2015-08-18
    参数： person_id 当前登录用户ID,current_role_ids_str 当前角色ID,identity_id 身份ID
    返回值：存储结果的table
]]
local function getRoleOrgsByRoleIdsAndPersonId(self,person_id,current_role_ids_str,identity_id)
	local roleModel = require "base.role.model.RoleModel";
	local orgTable = roleModel:getRoleOrgsByRoleIdsAndPersonId(person_id,current_role_ids_str,identity_id);

    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=orgTable };
end
_RoleService.getRoleOrgsByRoleIdsAndPersonId = getRoleOrgsByRoleIdsAndPersonId;
---------------------------------------------------------------------------

local function getRoleOrgTreeByRoleIdsAndPersonId(self,person_id,current_role_ids_str,identity_id)
	local roleModel = require "base.role.model.RoleModel";
	local orgTable = roleModel:getRoleOrgsByRoleIdsAndPersonId(person_id,current_role_ids_str,identity_id);
	--"pId":-1,"org_code":"_200113362_","id":200113362,"name":"东北师范大学","open":true
    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    local returnValue={}
	--{"ORG_NAME":"北京市教育厅","PARENT_ID":0,"ORG_ID":100001,"ORG_CODE":"_100001_"}
	for index=1,#orgTable do 
		local returnTable={};
		returnTable["pId"]=orgTable[index]["PARENT_ID"];
		returnTable["id"]=orgTable[index]["ORG_ID"];
		returnTable["name"]=orgTable[index]["ORG_NAME"];
		returnTable["org_code"]=orgTable[index]["ORG_CODE"];
		returnTable["open"]=true;
		returnValue[index]=returnTable
	end	
    return { success=true, table_List=returnValue };
end
_RoleService.getRoleOrgTreeByRoleIdsAndPersonId = getRoleOrgTreeByRoleIdsAndPersonId;
---------------------------------------------------------------------------
--[[

级联获取角色组织，如果是教育局查询到部门，其他的org_type则一直向下查询
]]
local function getHierachyRoleOrgTreeByRoleIdsAndPersonId(self,person_id,current_role_ids_str,identity_id)
	local roleModel = require "base.role.model.RoleModel";
	local orgService = require "base.organization.services.OrgService";
	local orgTable = roleModel:getRoleOrgsByRoleIdsAndPersonId(person_id,current_role_ids_str,identity_id);
	--"pId":-1,"org_code":"_200113362_","id":200113362,"name":"东北师范大学","open":true
    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
	
    local returnValue={}
	local m=1;
	--[[
	local temp={};
	temp["pId"]=0;
	temp["id"]=-1;
	temp["name"]="管理部门";
	temp["open"]=true;
	returnValue[m]=temp;
		m=m+1;
	]]
	for index=1,#orgTable do 
		local returnTable={};
		returnTable["pId"]=orgTable[index]["PARENT_ID"];
		local org_id=orgTable[index]["ORG_ID"];
		returnTable["id"]=org_id;
		returnTable["name"]=orgTable[index]["ORG_NAME"];
		returnTable["org_code"]=orgTable[index]["ORG_CODE"];
		returnTable["open"]=true;
		returnValue[m]=returnTable;
		m=m+1;
		
		local org_type=orgTable[index]["ORG_TYPE"];
		local orgResult;
		if tonumber(org_type)==1 then 
			orgResult=orgService:getOrgTree(org_id,3);
		
		else
			orgResult=orgService:getOrgTree(org_id,"");
		end
		for j=1,#orgResult do 
			local org_id1=orgResult[j]["id"];
			if tonumber(org_id1)~=tonumber(org_id) then
				local returnTable1={};
				returnTable1["pId"]=orgResult[j]["pId"];
				returnTable1["id"]=org_id1;
				returnTable1["name"]=orgResult[j]["name"];
				returnTable1["org_code"]=orgResult[j]["org_code"];
				returnTable1["open"]=false;
				returnValue[m]=returnTable1;
				m=m+1;
			end
		end		
	end	
    return  { success=true, table_List=returnValue }; 
end
_RoleService.getHierachyRoleOrgTreeByRoleIdsAndPersonId = getHierachyRoleOrgTreeByRoleIdsAndPersonId;
---------------------------------------------------------------------------


--[[

	根据角色编码和人员信息获取人员管理的组织
]]
local function getRoleOrgTreeByRoleCodeAndPersonId(self,person_id,role_code,identity_id) 
	local roleModel = require "base.role.model.RoleModel";
	local role=roleModel:getRoleByRoleCode(role_code);
	if not role then
		return { success=false, info="没有该角色编码" };
	end
	local roleId = role["ROLE_ID"];
	local orgTable = roleModel:getRoleOrgsByRoleIdsAndPersonId(person_id,roleId,identity_id);

    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=orgTable };

end
_RoleService.getRoleOrgTreeByRoleCodeAndPersonId = getRoleOrgTreeByRoleCodeAndPersonId;

--[[

	根据角色编码和人员信息获取人员管理的组织
]]
local function getRoleOrgTreeByRoleIdsAndPersonId1(self,person_id,current_role_ids_str,identity_id)
	local roleModel = require "base.role.model.RoleModel";
	local orgTable = roleModel:getRoleOrgsByRoleIdsAndPersonId(person_id,current_role_ids_str,identity_id);
	--"pId":-1,"org_code":"_200113362_","id":200113362,"name":"东北师范大学","open":true
    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    local returnValue={}
	--{"ORG_NAME":"北京市教育厅","PARENT_ID":0,"ORG_ID":100001,"ORG_CODE":"_100001_"}
	for index=1,#orgTable do 
		local returnTable={};
		returnTable["pId"]=orgTable[index]["PARENT_ID"];
		returnTable["id"]=orgTable[index]["ORG_ID"];
		returnTable["name"]=orgTable[index]["ORG_NAME"];
		returnTable["org_code"]=orgTable[index]["ORG_CODE"];
		returnTable["isParent"]=true;
		returnValue[index]=returnTable
	end	
    return returnValue;
end
_RoleService.getRoleOrgTreeByRoleIdsAndPersonId1 = getRoleOrgTreeByRoleIdsAndPersonId1;

--[[

	根据角色编码和人员信息获取人员管理的组织
]]
local function getRolesByRoleIds(self,role_ids)
	local roleModel = require "base.role.model.RoleModel";
	local roleTable= roleModel:getRolesByRoleIds(role_ids);
	 if not roleTable then
        return { success=false, info="获取数据失败" };
    end
	local result={};
	result.success=true;
	result.tableList=roleTable;
    return result;
end
_RoleService.getRolesByRoleIds = getRolesByRoleIds;
return _RoleService;