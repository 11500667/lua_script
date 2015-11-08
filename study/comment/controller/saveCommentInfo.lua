--
-- 学生点评 -> 保存点评信息
-- 请求方式：POST
-- 作者: shenjian
-- 日期: 2015/5/5 15:57
--

-- 1.获取参数
local request_method = ngx.var.request_method;
local args;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["obj_type"] == nil or args["obj_type"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数obj_type不能为空！\"}");
    return;
elseif args["obj_id"] == nil or args["obj_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数obj_id不能为空！\"}");
    return;
elseif args["person_id"] == nil or args["person_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数person_id不能为空！\"}");
    return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
    return;
end


local objType    = tonumber(args["obj_type"]);
local objId      = tonumber(args["obj_id"]);
local personId   = tonumber(args["person_id"]);
local identityId = tonumber(args["identity_id"]);

local classId = 0;
if args["class_id"] ~= nil and args["class_id"] ~= "" then
   classId = tonumber(args["class_id"]);
end

local itemScore1 = 0;
if args["item_score1"] ~= nil and args["item_score1"] ~= "" then
   itemScore1 = tonumber(args["item_score1"]);
end

local itemScore2 = 0;
if args["item_score2"] ~= nil and args["item_score2"] ~= "" then
    itemScore2 = tonumber(args["item_score2"]);
end

local itemScore3 = 0;
if args["item_score3"] ~= nil and args["item_score3"] ~= "" then
    itemScore3 = tonumber(args["item_score3"]);
end

local itemScore4 = 0;
if args["item_score4"] ~= nil and args["item_score4"] ~= "" then
    itemScore4 = tonumber(args["item_score4"]);
end

local commentText = "";
if args["comment_text"] ~= nil and args["comment_text"] ~= "" then
    commentText = args["comment_text"];
end

local paramTable = {};
paramTable["obj_type"]     = objType;
paramTable["obj_id"]       = objId;
paramTable["person_id"]    = personId;
paramTable["identity_id"]  = identityId;
paramTable["class_id"]     = classId;
paramTable["item_score1"]  = itemScore1;
paramTable["item_score2"]  = itemScore2;
paramTable["item_score3"]  = itemScore3;
paramTable["item_score4"]  = itemScore4;
paramTable["comment_text"] = commentText;

local commentService = require "study.comment.services.CommentService";
local resultJsonObj  = commentService: saveCommentInfo(paramTable);

local cjson = require "cjson";
ngx.print(cjson.encode(resultJsonObj));