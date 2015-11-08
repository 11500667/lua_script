
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题反馈处理
-- 作者：刘全锋
-- 日期：2015年9月18日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local cjson = require "cjson"

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local fieldTable = {};


local feedback_id		= args["feedback_id"];
local feedback_status	= args["feedback_status"];
local deal_content		= args["deal_content"];

if feedback_id == nil or feedback_id == "" then
    ngx.say("{\"success\":false,\"info\":\"feedback_id参数错误！\"}");
    return;
end

if feedback_status == nil or feedback_status == "" then
    ngx.say("{\"success\":false,\"info\":\"feedback_status参数错误！\"}");
    return;
end


if deal_content == nil or deal_content == "" then
    ngx.say("{\"success\":false,\"info\":\"deal_content参数错误！\"}");
    return;
end

fieldTable["feedback_id"]	        = feedback_id;
fieldTable["feedback_status"]		= feedback_status;
fieldTable["deal_content"]	        = deal_content;

local questionModel = require "management.question.model.QuestionModel";
local result     = questionModel.updateFeedBack(fieldTable);

local responseJson = {}

responseJson["success"] = result;

if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.say(cjson.encode(responseJson));