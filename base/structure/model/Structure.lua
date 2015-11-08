--
-- 章节目录、知识点结构的基础函数
-- User: 申健
-- Date: 2015/5/10
--

local _Structure = {};

-- ----------------------------------------------------------------------------------------------
--[[
    描述：   插入学情分析的统计数据
    参数：   dataTable       存储数据的table对象
    返回值：   true保存成功，fasle保存失败
]]
local function getKnowledgeBySubject(self, subjectId)
    
    local querySql    = "SELECT T1.SCHEME_ID, T2.STRUCTURE_ID, T2.STRUCTURE_NAME, T2.PARENT_ID, T2.STRUCTURE_CODE FROM T_RESOURCE_SCHEME T1 INNER JOIN T_RESOURCE_STRUCTURE T2 ON T1.SCHEME_ID = T2.SCHEME_ID_INT AND T1.TYPE_ID=2 and T1.B_USE=1 AND T2.PARENT_ID=-1 WHERE T1.SUBJECT_ID=" .. subjectId .. ";";
    local DBUtil      = require "common.DBUtil";
    local queryResult = DBUtil:querySingleSql(querySql);
    if not queryResult then
        return false, false, "获取知识点数据失败";
    end

    if #queryResult == 0 then
        return true, false, "该科目下没有知识点";
    end

    local resultRecord = {};
    resultRecord["id"]             = queryResult[1]["STRUCTURE_ID"];
    resultRecord["pId"]            = queryResult[1]["PARENT_ID"];
    resultRecord["name"]           = queryResult[1]["STRUCTURE_NAME"];
    resultRecord["structure_code"] = queryResult[1]["STRUCTURE_CODE"];
    resultRecord["isParent"]       = true;
    resultRecord["scheme_id"]      = queryResult[1]["SCHEME_ID"];

    return true, true, resultRecord;
end
_Structure.getKnowledgeBySubject = getKnowledgeBySubject;
-- ----------------------------------------------------------------------------------------------
--[[
    描述：   获取节点的STRUCTURE_CODE
    参数：   structureId    节点的ID
    返回值： 节点ID
]]
local function getStrucCodeById(self, structureId)
    local _CacheUtil = require "common.CacheUtil";
    local strucCode = _CacheUtil:hget("t_resource_structure_" .. structureId, "structure_code");
    if not strucCode then
        strucCode = 0;
    end
    return strucCode;
end

_Structure.getStrucCodeById = getStrucCodeById;
-- ----------------------------------------------------------------------------------------------

return _Structure;    