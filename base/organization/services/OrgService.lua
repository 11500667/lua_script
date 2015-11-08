--[[
	胡悦
	组织接口
]]

local _OrgService = {};


--[[
    描述：根据组织ID获取一层子节点
]]
local function getChildrenOrgs(self,orgId,orgType)
	local orgModel = require "base.organization.model.OrgModel";
	local orgTable = orgModel:getChildrenOrgs(orgId,orgType)

    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=orgTable };

end

_OrgService.getChildrenOrgs = getChildrenOrgs;
---------------------------------------------------------------------------

--[[
    描述：根据组织ID获取一层子节点
]]
local function getHierarchyChildrenOrgs(self,orgId,orgType)
	local orgModel = require "base.organization.model.OrgModel";
	local orgTable = orgModel:getHierarchyChildrenOrgs(orgId,orgType)

    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    
    return { success=true, table_List=orgTable };

end

_OrgService.getHierarchyChildrenOrgs = getHierarchyChildrenOrgs;
---------------------------------------------------------------------------
--[[
    描述：根据组织ID获取组织详情
]]
local function getOrgByOrgId(self,orgId)
	local orgModel = require "base.organization.model.OrgModel";
	local orgTable = orgModel:getOrgByOrgId(orgId)

    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    
    return orgTable;

end

_OrgService.getOrgByOrgId = getOrgByOrgId;
---------------------------------------------------------------------------
--[[
    描述：根据组织ID获取上级单位
]]
local function getSupOrgByOrgId(self,orgId)
	local orgModel = require "base.organization.model.OrgModel";
	local orgTable = orgModel:getSupOrgByOrgId(orgId)

    if not orgTable then
        return { success=false, info="获取数据失败" };
    end
    
    return orgTable;

end

_OrgService.getSupOrgByOrgId = getSupOrgByOrgId;
---------------------------------------------------------------------------

--[[
	获取组织树
]]
local function getOrgTree(self,org_id,org_type) 
	local orgModel = require "base.organization.model.OrgModel";
	local orgTable = orgModel:getOrgTree(org_id,org_type)
	if not orgTable then
	  return {};
	end
	return orgTable;
end
_OrgService.getOrgTree = getOrgTree;
---------------------------------------------------------------------------
--[[

--根据组织ID检查是否是否有分校
]]
local function checkHaveBranchSchool(self,org_id)
	local orgModel = require "base.organization.model.OrgModel";
	ngx.log(ngx.ERR,"--------------"..org_id);
	local result = orgModel:checkHaveBranchSchool(org_id);
	return result;
end
_OrgService.checkHaveBranchSchool = checkHaveBranchSchool;
---------------------------------------------------------------------------
--[[
获取分校及其组织信息
]]
local function getBranchSchoolAndOrg(self,org_id) 
	local orgModel = require "base.organization.model.OrgModel";
	local result = orgModel:getBranchSchoolAndOrg(org_id);
	return result;
end
_OrgService.getBranchSchoolAndOrg = getBranchSchoolAndOrg;

--[[
获取分校及其组织信息
]]
local function getOrgRelation(self,org_id) 
	local orgModel = require "base.organization.model.OrgModel";
	local result={};
	local current_org_res = orgModel:getOrgByOrgId(org_id);
	local current_org={}
	if current_org_res == nil then 
	
	else
		
		current_org["ORG_NAME"]=current_org_res["ORG_NAME"];
		current_org["ORG_ID"]=current_org_res["ORG_ID"];
		current_org["ORG_TYPE"]=current_org_res["ORG_TYPE"];
	end
	result.current_org=current_org;
	local sup_org= orgModel:getSupOrgByOrgId(org_id);
	result.sup_org=sup_org;
	local sub_org=getHierarchyChildrenOrgs(orgId,"");
	result.sub_org=sub_org;
	return result;
end
_OrgService.getOrgRelation = getOrgRelation;
--[[
	根据行政区划Id获取默认教育局
]]
local function getDefaultEducationBureau(self,area_id) 
	local orgModel = require "base.organization.model.OrgModel";
	local result = orgModel:getDefaultEducationBureau(area_id);
	return result;
end
_OrgService.getDefaultEducationBureau = getDefaultEducationBureau;
--[[
	获取可编辑的单位类型
]]

return _OrgService;
