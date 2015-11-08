
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

local review_id 	= args["review_id"];

if review_id == nil or review_id == "" then
    ngx.say("{\"success\":false,\"info\":\"review_id参数错误！\"}");
    return;
end

local questionModel = require "management.question.model.QuestionModel";
local result     = questionModel.delReview(review_id);

local responseJson = {}

responseJson["success"] = result;

if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.say(cjson.encode(responseJson));