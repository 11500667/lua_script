-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题审核
-- 作者：刘全锋
-- 日期：2015年9月7日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local DBUtil   = require "common.DBUtil";
local cjson = require "cjson";
local p_myTs      = require "resty.TS"
local currentTS = p_myTs.getTs();
local CacheUtil = require "common.CacheUtil";
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


local question_id = tostring(args["question_id"]);

--试题id
if question_id == "nil" or question_id == "" then
    ngx.say("{\"success\":false,\"info\":\"question_id参数错误！\"}")
    return
end


local check_type = tostring(args["check_type"]);
--操作类型
if check_type == "nil" or check_type == "" then
    ngx.say("{\"success\":false,\"info\":\"check_type参数错误！\"}")    
    return
end

local question_id_table = Split(question_id, ",");

local questionModel = require "management.question.model.QuestionModel";


local result = questionModel.examineQuestion(question_id_table,check_type);


local returnjson={};
if not result then 
    returnjson.success = false;
    returnjson.info = "试题审核失败！";
else
    returnjson.success = true;
    returnjson.info = "试题审核成功！";
end


ngx.say(encodeJson(returnjson));

