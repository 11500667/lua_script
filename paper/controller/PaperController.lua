-- -----------------------------------------------------------------------------------
-- 文件描述： controller类：试卷对应的接口
-- 日    期： 2015年10月30日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------
local _PaperCtl = {};
local _PaperService = require "paper.service.PaperService";

-- -----------------------------------------------------------------------------------
-- 函数描述： controller函数：根据 paper_id_int 获取试卷对应的信息
-- 日    期： 2015年10月30日
-- 参    数： 无
-- 返 回 值： 返回值信息
-- -----------------------------------------------------------------------------------
local function getPaperInfoByIdInt(self)
    local paperIdInt = self: getParamByName("paper_id_int", true);
    local paperCache  = _PaperService: getPaperByIdIntAndGroup(paperIdInt, "");
    if not paperCache then
    	self:printJson({success = false, info = "获取试卷信息出错"});
    else
    	self:printJson({success = true, paper_info = paperCache});
    end
end
_PaperCtl.getPaperInfoByIdInt = getPaperInfoByIdInt;


BaseController:initController(_PaperCtl);