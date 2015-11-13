
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


local question_id_char 	= args["question_id_char"];

if question_id_char == nil or question_id_char == "" then
ngx.say("{\"success\":false,\"info\":\"question_id_char参数错误！\"}");
return;
end

local structure_ids 	= args["structure_ids"];

if structure_ids == nil or structure_ids == "" then
    ngx.say("{\"success\":false,\"info\":\"structure_ids参数错误！\"}");
    return;
end


local structure_ids_table = Split(structure_ids, ",");


local questionModel = require "management.question.model.QuestionModel";


local result     = questionModel.delQuestion(question_id_char,structure_ids_table);

local responseJson = {}

responseJson["success"] = result;

if result then
    responseJson["info"] = "操作成功";
else
    responseJson["info"] = "操作失败";
end

ngx.say(cjson.encode(responseJson));








