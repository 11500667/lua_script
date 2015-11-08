-- -----------------------------------------------------------------------------------
-- 描述：多级审核 -> 多级门户推荐的服务类
-- 日期：2015年8月25日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local resInfoModel = require "resource.model.ResourceInfo";
local paperInfoModel = require "paper.model.PaperInfoModel";
local wkdsModel      = require "wkds.model.WkdsModel";
local recommendModel = require "multi_check.model.Recommend";
local ssdbUtil       = require "common.SSDBUtil";
local redisUtil      = require "common.CacheUtil";

local sysTypeStrArray = {"zy", "wk", "bk", "sj"};

local _RecommendService = {};

local function saveRecommend(self, paramTable)
    local infoId    = paramTable["info_id"];
    local objType   = recommendModel: getObjTypeBySysTypeInt(paramTable["sys_type"]);
    local objIdInt, objIdChar  = recommendModel: getObjIdInt(objType, infoId);
    paramTable["obj_type"]     = objType;
    paramTable["obj_id_int"]   = objIdInt;
    paramTable["obj_id_char"]  = objIdChar; 
    local stageId   = paramTable["stage_id"];
    local subjectId = paramTable["subject_id"];
    local personId  = paramTable["person_id"];
    local unitId    = paramTable["unit_id"];
    local sortTs    = paramTable["sort_ts"];

    -- 获取对应info表的记录的ID
    local infoId = nil;
    if objType == 1 or objType == 4 then -- 资源、备课
        local resCache = resInfoModel: getByBaseIdAndGroupId(objIdInt, unitId);
        infoId = resCache["id"];
    elseif objType == 3 then -- 试卷
        local paperCache = paperInfoModel: getByBaseIdAndGroupId(objIdInt, unitId);
        infoId = paperCache["id"];
    elseif objType == 5 then -- 微课
        infoId = wkdsModel: getInfoIdByWkdsIdInt(objIdInt, unitId);
    end
    paramTable["obj_info_id"] = infoId;

    -- 将数字类型的sys_type 转换为字符类型的sys_type,对应关系：1->zy, 2->wk, 3->bk, 4->sj
    local tempSysTypeStr = sysTypeStrArray[tonumber(paramTable["sys_type"])];
    ssdbUtil:zset("tuijian_"..tempSysTypeStr.."_"..unitId, infoId, sortTs);
    ssdbUtil:zset("tuijian_"..tempSysTypeStr.."_"..unitId.."_"..stageId, infoId, sortTs);
    ssdbUtil:zset("tuijian_"..tempSysTypeStr.."_"..unitId.."_"..stageId.."_"..subjectId, infoId, sortTs);

    --再记一遍人员
    ssdbUtil:zset("tuijian_"..tempSysTypeStr.."_"..unitId.."_"..personId, infoId, sortTs);
    ssdbUtil:zset("tuijian_"..tempSysTypeStr.."_"..unitId.."_"..stageId.."_"..personId, infoId, sortTs);
    ssdbUtil:zset("tuijian_"..tempSysTypeStr.."_"..unitId.."_"..stageId.."_"..subjectId.."_"..personId, infoId, sortTs);

    local  update_ts = math.random(1000000) .. os.time();

    redisUtil:set("tuijian_ts_" .. unitId, update_ts);
    redisUtil:del("tuijian_" .. tempSysTypeStr .. "_ts_" .. unitId);

    -- 向 mysql 中保存推荐记录
    return recommendModel: saveRecommend(paramTable);
end

_RecommendService.saveRecommend = saveRecommend;


return _RecommendService;