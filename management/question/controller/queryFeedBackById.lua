
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题反馈根据id查询
-- 作者：刘全锋
-- 日期：2015年9月18日
-- -----------------------------------------------------------------------------------

ngx.header.content_type = "text/plain";
local request_method = ngx.var.request_method;
local cjson = require "cjson";

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local feedback_id   = args["feedback_id"];

if feedback_id == nil or feedback_id == "" then
    ngx.say("{\"success\":false,\"info\":\"feedback_id参数错误！\"}");
    return;
end

local questionModel = require "management.question.model.QuestionModel";


local result = questionModel.queryFeedBackById(feedback_id);


ngx.print(cjson.encode(result));





