--
-- 章节目录、知识点结构的服务函数
-- User: 申健
-- Date: 2015/5/10
--

local _StructureService = {};

-- ----------------------------------------------------------------------------------------------
--[[
    描述：   插入学情分析的统计数据
    参数：   dataTable       存储数据的table对象
    返回值：   true保存成功，fasle保存失败
]]
local function getKnowledgeBySubject(self, subjectId)
    
    local structureModel = require "base.structure.model.Structure";
    local succFlag, isExistFlag, resultRecord = structureModel: getKnowledgeBySubject(subjectId);

    if not succFlag then -- 执行出错
        return { success = succFlag, is_exist = isExistFlag, info = resultRecord };
    elseif not isExistFlag then -- 没有知识点
        return { success = succFlag, is_exist = isExistFlag, info = resultRecord };
    else -- 获取成功
        return { success = succFlag, is_exist = isExistFlag, root_node = resultRecord };
    end
end
_StructureService.getKnowledgeBySubject = getKnowledgeBySubject;
-- ----------------------------------------------------------------------------------------------
--[[
    描述：     获取审核对象所在的节点的路径
    参数：     strucIdInt       节点的ID
    返回值：   structurePath    节点的路径
]]
local function getStrucPath(self, strucIdInt)
    
    local cacheUtil = require "common.CacheUtil";
    local cjson = require "cjson";
    -- ngx.log(ngx.ERR, "[sj_log] -> [structure] -> strucIdInt ->[", cjson.encode(strucIdInt), "]");

    local structurePath = ""
    local p_structures = cacheUtil:zrange("structure_code_"..strucIdInt, 0, -1);
    -- ngx.log(ngx.ERR, "[sj_log] -> [structure] -> p_structures ->[", cjson.encode(p_structures), "]");
    for i = 1, #p_structures do
        local strucName = cacheUtil:hget("t_resource_structure_" .. p_structures[i], "structure_name");
        structurePath   = structurePath .. strucName .. "->";
    end
    structurePath = string.sub(structurePath, 0, #structurePath-2);
    
    return structurePath;
end

_StructureService.getStrucPath = getStrucPath;
-- ----------------------------------------------------------------------------------------------

return _StructureService;