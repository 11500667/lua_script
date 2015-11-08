
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 根据学段学科查询题型
-- 作者：刘全锋
-- 日期：2015年10月15日
-- -----------------------------------------------------------------------------------

local cookie_stage_id = tostring(ngx.var.cookie_background_stage_id)
local cookie_subject_id = tostring(ngx.var.cookie_background_subject_id)


--判断是否有cookie_stage_id
if cookie_stage_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_stage_id参数错误！\"}")
    return
end


--判断是否有subject_id的cookie信息
if cookie_subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_subject_id参数错误！\"}")
    return
end


local questionModel = require "management.question.model.QuestionModel";

local result,returnjson     = questionModel.getQtBySubject(cookie_stage_id, cookie_subject_id);

if not result then
    returnjson={};
    returnjson.success = false;
    returnjson.info = "查询信息失败！";
end

ngx.print(encodeJson(returnjson));
