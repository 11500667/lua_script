-- -----------------------------------------------------------------------------------
-- 描述：多级审核 -> 门户推荐的 controller 类
-- 日期：2015年8月22日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local recommendService = require "multi_check.service.RecommendService";

local _RecommendController = {}

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 生成mysql事务处理的对象
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------

function _RecommendController: saveRecommend()
    
    local infoId    = self: getParamToNumber("info_id"    , true);
    local sysType   = self: getParamByName  ("sys_type"   , true);
    local stageId   = self: getParamToNumber("stage_id"   , true);
    local subjectId = self: getParamToNumber("subject_id" , true);
    local personId  = self: getParamToNumber("person_id"  , true);
    local unitId    = self: getParamToNumber("unit_id"    , true);
    local currentTS = getTS();


    local paramTable = {};
    paramTable["info_id"]     = infoId;
    paramTable["sys_type"]    = sysType;
    paramTable["stage_id"]    = stageId;
    paramTable["subject_id"]  = subjectId;
    paramTable["person_id"]   = personId;
    paramTable["unit_id"]     = unitId;
    paramTable["sort_ts"]     = currentTS;
    paramTable["b_top"]       = 0;

    local result    = recommendService: saveRecommend(paramTable);
    local newInfoId = ngx.ctx["new_info_id"]

    local jsonResult = {};
    if result then
        jsonResult["success"] = true;
        jsonResult["info_id"] = newInfoId;
    else
        jsonResult["success"] = false;
        jsonResult["info"]    = "推荐失败";
    end
    ngx.print(encodeJson(jsonResult));
end

BaseController: initController(_RecommendController);